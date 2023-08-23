import CacheClient
import ClientPrelude
import EngineKit
import GatewayAPI
import SharedModels

// MARK: - AccountPortfoliosClient + DependencyKey
extension AccountPortfoliosClient: DependencyKey {
	/// Internal state that holds all loaded portfolios.
	actor State {
		let portfoliosSubject: AsyncCurrentValueSubject<[AccountAddress: AccountPortfolio]> = .init([:])

		func setAccountPortfolio(_ portfolio: AccountPortfolio) {
			portfoliosSubject.value.updateValue(portfolio, forKey: portfolio.owner)
		}

		func setAccountPortfolios(_ portfolios: [AccountPortfolio]) {
			portfolios.forEach(setAccountPortfolio)
		}

		func portfolioForAccount(_ address: AccountAddress) -> AnyAsyncSequence<AccountPortfolio> {
			portfoliosSubject.compactMap { $0[address] }.eraseToAnyAsyncSequence()
		}
	}

	public static let liveValue: AccountPortfoliosClient = {
		let state = State()

		@Dependency(\.cacheClient) var cacheClient

		@Sendable
		func fetchAccountPortfolio(_ accountAddress: AccountAddress, refresh: Bool) async throws -> AccountPortfolio {
			let portfolio = try await cacheClient.withCaching(
				cacheEntry: .accountPortfolio(.single(accountAddress.address)),
				forceRefresh: refresh,
				request: { try await AccountPortfoliosClient.fetchAccountPortfolio(accountAddress) }
			)

			await state.setAccountPortfolio(portfolio)

			return portfolio
		}

		return AccountPortfoliosClient(
			fetchAccountPortfolios: { accountAddresses, forceRefresh in
				let portfolios = try await {
					// TODO: This logic might be a good candidate for shared logic in cacheClient. When it is wanted to load multiple models as bulk and save independently.

					// Refresh all accounts
					if forceRefresh {
						let allPortfolios = try await AccountPortfoliosClient.fetchAccountPortfolios(accountAddresses)
						allPortfolios.forEach {
							cacheClient.save($0, .accountPortfolio(.single($0.owner.address)))
						}
						return allPortfolios
					}

					// Otherwise, load the valid portfolios from the cache
					let cachedPortfolios = accountAddresses.compactMap {
						try? cacheClient.load(AccountPortfolio.self, .accountPortfolio(.single($0.address))) as? AccountPortfolio
					}

					let notCachedPortfolios = Set(accountAddresses).subtracting(Set(cachedPortfolios.map(\.owner)))

					guard !notCachedPortfolios.isEmpty else {
						return cachedPortfolios
					}

					// Fetch the remaining portfolios from the GW. Either the portfolios were expired in the cache, or missing
					let freshPortfolios = try await AccountPortfoliosClient.fetchAccountPortfolios(Array(notCachedPortfolios))
					freshPortfolios.forEach {
						cacheClient.save($0, .accountPortfolio(.single($0.owner.address)))
					}

					return cachedPortfolios + freshPortfolios
				}()

				// Update the current account portfolios
				await state.setAccountPortfolios(portfolios)

				return portfolios
			},
			fetchAccountPortfolio: { accountAddress, forceRefresh in
				let portfolio = try await cacheClient.withCaching(
					cacheEntry: .accountPortfolio(.single(accountAddress.address)),
					forceRefresh: forceRefresh,
					request: { try await AccountPortfoliosClient.fetchAccountPortfolio(accountAddress) }
				)

				await state.setAccountPortfolio(portfolio)

				return portfolio
			},
			portfolioForAccount: { address in
				await state.portfolioForAccount(address)
			},
			portfolios: { state.portfoliosSubject.value.map(\.value) }
		)
	}()
}

extension AccountPortfoliosClient {
	struct EmptyAccountDetails: Error {}

	@Sendable
	static func fetchAccountPortfolios(
		_ addresses: [AccountAddress]
	) async throws -> [AccountPortfolio] {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let details = try await gatewayAPIClient.fetchResourceDetails(addresses.map(\.address), explicitMetadata: .resourceMetadataKeys)
		return try await details.items.parallelMap {
			try await createAccountPortfolio($0, ledgerState: details.ledgerState)
		}
	}

	@Sendable
	static func fetchAccountPortfolio(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let accountDetails = try await gatewayAPIClient.fetchResourceDetails([accountAddress.address], explicitMetadata: .resourceMetadataKeys)
		guard let accountItem = accountDetails.items.first else {
			throw EmptyAccountDetails()
		}
		return try await createAccountPortfolio(accountItem, ledgerState: accountDetails.ledgerState)
	}
}

extension AccountPortfoliosClient {
	@Sendable
	static func createAccountPortfolio(
		_ rawAccountDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio {
		let (rawFungibleResources, rawNonFungibleResources) = try await (
			fetchAllFungibleResources(rawAccountDetails, ledgerState: ledgerState),
			fetchAllNonFungibleResources(rawAccountDetails, ledgerState: ledgerState)
		)

		let poolUnitResources = try await createPoolUnitResources(
			rawAccountDetails.address,
			rawFungibleResources: rawFungibleResources.compactMap(\.vault),
			rawNonFungibleResources: rawNonFungibleResources.compactMap(\.vault),
			ledgerState: ledgerState
		)

		let filteredRawFungibleResources = rawFungibleResources.filter { rawItem in
			!poolUnitResources.fungibleResourceAddresses.contains(rawItem.resourceAddress)
		}

		let filteredRawNonFungibleResources = rawNonFungibleResources.filter { rawItem in
			!poolUnitResources.nonFungibleResourceAddresses.contains(rawItem.resourceAddress)
		}

		async let fungibleResources = createFungibleResources(
			rawItems: filteredRawFungibleResources,
			ledgerState: ledgerState
		)
		async let nonFungibleResources = createNonFungibleResources(
			rawAccountDetails.address,
			rawItems: filteredRawNonFungibleResources,
			ledgerState: ledgerState
		)

		let isDappDefintionAccountType = rawAccountDetails.metadata.accountType == .dappDefinition

		return try await AccountPortfolio(
			owner: .init(validatingAddress: rawAccountDetails.address),
			isDappDefintionAccountType: isDappDefintionAccountType,
			fungibleResources: fungibleResources,
			nonFungibleResources: nonFungibleResources,
			poolUnitResources: poolUnitResources
		)
	}

	@Sendable
	static func createFungibleResources(
		rawItems: [GatewayAPI.FungibleResourcesCollectionItem],
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio.FungibleResources {
		// We are interested in vault aggregated items
		let rawItems = rawItems.compactMap(\.vault)
		guard !rawItems.isEmpty else {
			return .init()
		}

		return try await rawItems.asyncMap {
			try await createFungibleResource($0, ledgerState: ledgerState)
		}.sorted()
	}

	@Sendable
	static func createFungibleResource(_ resource: GatewayAPI.FungibleResourcesCollectionItemVaultAggregated, ledgerState: GatewayAPI.LedgerState) async throws -> AccountPortfolio.FungibleResource {
		let amount: BigDecimal = {
			// Resources of an account always have one single vault which stores the value.
			guard let resourceVault = resource.vaults.items.first else {
				loggerGlobal.warning("Account Portfolio: \(resource.resourceAddress) does not have any vaults")
				return .zero
			}

			do {
				return try BigDecimal(fromString: resourceVault.amount)
			} catch {
				loggerGlobal.error(
					"Account Portfolio: Failed to parse amount for resource: \(resource.resourceAddress), reason: \(error.localizedDescription)"
				)
				return .zero
			}
		}()

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let item = try await gatewayAPIClient.getSingleEntityDetails(resource.resourceAddress)
		let details = item.details?.fungible

		let resourceAddress = try ResourceAddress(validatingAddress: resource.resourceAddress)
		let divisibility = details?.divisibility
		let behaviors = (details?.roleAssignments).map(extractBehaviors) ?? []
		let tags = extractTags(item: item)
		let totalSupply = details.flatMap { try? BigDecimal(fromString: $0.totalSupply) }
		let metadata = resource.explicitMetadata

		return AccountPortfolio.FungibleResource(
			resourceAddress: resourceAddress,
			amount: amount,
			divisibility: divisibility,
			name: metadata?.name,
			symbol: metadata?.symbol,
			description: metadata?.description,
			iconURL: metadata?.iconURL,
			behaviors: behaviors,
			tags: tags,
			totalSupply: totalSupply
		)
	}

	@Sendable
	static func createNonFungibleResources(
		_ accountAddress: String,
		rawItems: [GatewayAPI.NonFungibleResourcesCollectionItem],
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio.NonFungibleResources {
		// We are interested in vault aggregated items
		let vaultItems = rawItems.compactMap(\.vault)
		return try await vaultItems.parallelMap { resource in
			try await createNonFungibleResource(accountAddress, resource, ledgerState: ledgerState)
		}.sorted()
	}

	@Sendable
	static func createNonFungibleResource(
		_ accountAddress: String,
		_ resource: GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio.NonFungibleResource {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		@Sendable
		func getAllTokens(
			resource: GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated
		) async throws -> [String] {
			guard let vault = resource.vaults.items.first else { return [] }
			let firstPageItems = vault.items ?? []

			guard let nextPageCursor = vault.nextCursor else {
				return firstPageItems
			}

			let additionalItems = try await fetchAllPaginatedItems(
				cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
				fetchEntityNonFungibleResourceIdsPage(
					accountAddress,
					resourceAddress: resource.resourceAddress,
					vaultAddress: vault.vaultAddress
				)
			)

			return firstPageItems + additionalItems
		}

		@Sendable
		func tokens(
			resource: GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated
		) async throws -> IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken> {
			let nftIDs = try await getAllTokens(resource: resource)

			// https://rdxworks.slack.com/archives/C02MTV9602H/p1681155601557349
			let maximumNFTIDChunkSize = 29

			var result: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken> = []
			for nftIDChunk in nftIDs.chunks(ofCount: maximumNFTIDChunkSize) {
				let tokens = try await gatewayAPIClient.getNonFungibleData(.init(
					atLedgerState: ledgerState.selector,
					resourceAddress: resource.resourceAddress,
					nonFungibleIds: Array(nftIDChunk)
				))
				.nonFungibleIds
				.map { item in
					let details = item.details
					let canBeClaimed = details.claimEpoch.map { UInt64(ledgerState.epoch) >= $0 } ?? false
					return try AccountPortfolio.NonFungibleResource.NonFungibleToken(
						id: .fromParts(
							resourceAddress: .init(address: resource.resourceAddress),
							nonFungibleLocalId: .from(stringFormat: item.nonFungibleId)
						),
						name: details.name,
						description: nil,
						keyImageURL: details.keyImageURL,
						metadata: [],
						stakeClaimAmount: details.claimAmount,
						canBeClaimed: canBeClaimed
					)
				}

				result.append(contentsOf: tokens)
			}

			return result
		}

		let item = try await gatewayAPIClient.getSingleEntityDetails(resource.resourceAddress)
		let details = item.details?.nonFungible

		let behaviors = (details?.roleAssignments).map(extractBehaviors) ?? []
		let tags = extractTags(item: item)
		let totalSupply = details.flatMap { try? BigDecimal(fromString: $0.totalSupply) }

		// Load the nftIds from the resource vault
		let tokens = try await tokens(resource: resource)
		let metadata = resource.explicitMetadata

		return try AccountPortfolio.NonFungibleResource(
			resourceAddress: .init(validatingAddress: resource.resourceAddress),
			name: metadata?.name,
			description: metadata?.description,
			iconURL: metadata?.iconURL,
			behaviors: behaviors,
			tags: tags,
			tokens: tokens,
			totalSupply: totalSupply
		)
	}
}

// MARK: Pool Units
extension AccountPortfoliosClient {
	@Sendable
	static func createPoolUnitResources(
		_ accountAddress: String,
		rawFungibleResources: [GatewayAPI.FungibleResourcesCollectionItemVaultAggregated],
		rawNonFungibleResources: [GatewayAPI.NonFungibleResourcesCollectionItemVaultAggregated],
		ledgerState: GatewayAPI.LedgerState
	) async throws -> AccountPortfolio.PoolUnitResources {
		let stakeUnitCandidates = rawFungibleResources.filter {
			$0.explicitMetadata?.validator != nil
		}

		let stakeClaimNFTCandidates = rawNonFungibleResources.filter {
			$0.explicitMetadata?.validator != nil
		}

		let poolUnitCandidates = rawFungibleResources.filter {
			$0.explicitMetadata?.pool != nil
		}

		func matchPoolUnitCandidate(
			for item: GatewayAPI.StateEntityDetailsResponseItem,
			candidates: [GatewayAPI.FungibleResourcesCollectionItemVaultAggregated],
			metadataAddressMatch: KeyPath<GatewayAPI.EntityMetadataCollection, String?>
		) -> GatewayAPI.FungibleResourcesCollectionItemVaultAggregated? {
			guard let poolUnitResourceAddress = item.explicitMetadata?.poolUnitResource else {
				assertionFailure("Pool Unit does not contain the pool unit resource address")
				return nil
			}

			guard let candidate = candidates.first(where: {
				$0.explicitMetadata?[keyPath: metadataAddressMatch] == item.address
			}) else {
				return nil
			}

			guard candidate.resourceAddress == poolUnitResourceAddress.address else {
				assertionFailure("Bad candidate, not declared by the pool unit")
				return nil
			}

			return candidate
		}

		let stakeAndPoolAddresses = stakeUnitCandidates.compactMap(\.explicitMetadata?.validator?.address)
			+ stakeClaimNFTCandidates.compactMap(\.explicitMetadata?.validator?.address)
			+ poolUnitCandidates.compactMap(\.explicitMetadata?.pool?.address)

		guard !stakeAndPoolAddresses.isEmpty else {
			return .init(radixNetworkStakes: [], poolUnits: [])
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient

		let networkId = await gatewaysClient.getCurrentNetworkID()
		let xrdAddress = knownAddresses(networkId: networkId.rawValue).resourceAddresses.xrd.addressString()

		let stakeAndPoolUnitDetails = try await gatewayAPIClient.fetchResourceDetails(
			stakeAndPoolAddresses,
			explicitMetadata: .poolUnitMetadataKeys,
			ledgerState: ledgerState
		)

		let stakeUnits = try await stakeAndPoolUnitDetails.items.asyncCompactMap { item -> AccountPortfolio.PoolUnitResources.RadixNetworkStake? in
			guard let validatorAddress = try? ValidatorAddress(validatingAddress: item.address) else {
				return nil
			}

			guard let state: GatewayAPI.ValidatorState = try? item.details?.component?.decodeState() else {
				assertionFailure("Invalid validator state")
				return nil
			}

			// Get the validator XRD resource
			guard let xrdResource = item
				.fungibleResources?
				.items
				.first(where: { $0.resourceAddress == xrdAddress })
			else {
				assertionFailure("A validator didn't contain an xrd resource")
				return nil
			}

			// Get the balance of the xrd by matching the vault address
			guard let xrdStakeVaultBalance = xrdResource
				.vault?
				.vaults
				.items
				.first(where: { $0.vaultAddress == state.stakeXRDVaultAddress })?.amount
			else {
				assertionFailure("Validtor XRD Resource didn't contain the \(state.stakeXRDVaultAddress) vault ")
				return nil
			}

			// Create validator with the information from the validator resource
			let validator = try AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator(
				address: validatorAddress,
				xrdVaultBalance: .init(fromString: xrdStakeVaultBalance),
				name: item.explicitMetadata?.name,
				description: item.explicitMetadata?.description,
				iconURL: item.explicitMetadata?.iconURL
			)

			let stakeUnitFungibleResource: AccountPortfolio.FungibleResource? = try await { () -> AccountPortfolio.FungibleResource? in
				let validatorStakeUnit = matchPoolUnitCandidate(
					for: item,
					candidates: stakeUnitCandidates,
					metadataAddressMatch: \.validator?.address
				)

				guard let validatorStakeUnit else {
					return nil
				}

				return try await createFungibleResource(validatorStakeUnit, ledgerState: ledgerState)
			}()

			// Extract the stake claim NFT, which might exist or not
			let stakeClaimNft: AccountPortfolio.NonFungibleResource? = try await { () -> AccountPortfolio.NonFungibleResource? in
				let stakeClaimNFTCandidate = stakeClaimNFTCandidates.first {
					$0.explicitMetadata?.validator?.address == item.address
				}

				// Check first if there is a candidate referencing the validator
				guard let stakeClaimNFTCandidate else {
					return nil
				}

				// Then validate that the validator is also referencing the candidate
				guard state.unstakeClaimTokenResourceAddress == stakeClaimNFTCandidate.resourceAddress else {
					assertionFailure("Bad stake claim nft candidate, not declared by the validator")
					return nil
				}

				// Create the NFT collection. NOTE: This will bring-in all the unstaking and ready to claim nft tokens.
				return try await createNonFungibleResource(accountAddress, stakeClaimNFTCandidate, ledgerState: ledgerState).nonEmpty

			}()

			// Either stakeUnit is present or stakeClaimNft
			if stakeUnitFungibleResource != nil || stakeClaimNft != nil {
				return .init(validator: validator, stakeUnitResource: stakeUnitFungibleResource, stakeClaimResource: stakeClaimNft)
			}

			return nil
		}

		let poolUnits = try await stakeAndPoolUnitDetails.items.asyncCompactMap { item -> AccountPortfolio.PoolUnitResources.PoolUnit? in
			guard let poolAddress = try? ResourcePoolAddress(validatingAddress: item.address) else {
				return nil
			}

			let poolUnitResourceCandidate = matchPoolUnitCandidate(
				for: item,
				candidates: poolUnitCandidates,
				metadataAddressMatch: \.pool?.address
			)

			guard let poolUnitResourceCandidate else {
				assertionFailure("Pool Unit not matched by any candidate")
				return nil
			}

			let allFungibleResources = try await fetchAllFungibleResources(item, ledgerState: ledgerState)

			guard !allFungibleResources.isEmpty else {
				assertionFailure("Empty Pool Unit!!!")
				return nil
			}

			let resources = try await createFungibleResources(
				rawItems: allFungibleResources,
				ledgerState: ledgerState
			)
			let poolUnitResource = try await createFungibleResource(
				poolUnitResourceCandidate,
				ledgerState: ledgerState
			)

			return .init(
				poolAddress: poolAddress,
				poolUnitResource: poolUnitResource,
				poolResources: resources
			)
		}

		return .init(radixNetworkStakes: stakeUnits, poolUnits: poolUnits)
	}
}

// MARK: - Endpoints
extension AccountPortfoliosClient {
	@Sendable
	static func fetchAllFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.FungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.fungibleResources else {
			return [GatewayAPI.FungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	// FIXME: Similar function to the above, maybe worth extracting in a single function?
	@Sendable
	static func fetchAllNonFungibleResources(
		_ entityDetails: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: GatewayAPI.LedgerState
	) async throws -> [GatewayAPI.NonFungibleResourcesCollectionItem] {
		guard let firstPage = entityDetails.nonFungibleResources else {
			return [GatewayAPI.NonFungibleResourcesCollectionItem]()
		}

		guard let nextPageCursor = firstPage.nextCursor else {
			return firstPage.items
		}

		let additionalItems = try await fetchAllPaginatedItems(
			cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
			fetchNonFungibleResourcePage(entityDetails.address)
		)

		return firstPage.items + additionalItems
	}

	static func fetchFungibleResourcePage(
		_ entityAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: entityAddress,
				aggregationLevel: .vault
			)
			let response = try await gatewayAPIClient.getEntityFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	static func fetchNonFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.NonFungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				aggregationLevel: .vault
			)
			let response = try await gatewayAPIClient.getEntityNonFungiblesPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}

	static func fetchEntityNonFungibleResourceIdsPage(
		_ accountAddress: String,
		resourceAddress: String,
		vaultAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<String> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityNonFungibleIdsPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				vaultAddress: vaultAddress,
				resourceAddress: resourceAddress
			)
			let response = try await gatewayAPIClient.getEntityNonFungibleIdsPage(request)

			return .init(
				loadedItems: response.items,
				totalCount: response.totalCount,
				cursor: response.nextCursor.map {
					PageCursor(ledgerState: response.ledgerState, nextPageCursor: $0)
				}
			)
		}
	}
}

// MARK: - Pagination
extension AccountPortfoliosClient {
	/// A page cursor is required to have the `nextPageCurosr` itself, as well the `ledgerState` of the previous page.
	struct PageCursor: Hashable, Sendable {
		let ledgerState: GatewayAPI.LedgerState
		let nextPageCursor: String
	}

	struct PaginatedResourceResponse<Resource: Sendable>: Sendable {
		let loadedItems: [Resource]
		let totalCount: Int64?
		let cursor: PageCursor?
	}

	/// Recursively fetches all of the pages for a given paginated request.
	///
	/// Provide an initial page cursor if needed to load the all the items starting with a given page
	@Sendable
	static func fetchAllPaginatedItems<Item>(
		cursor: PageCursor?,
		_ paginatedRequest: @Sendable @escaping (_ cursor: PageCursor?) async throws -> PaginatedResourceResponse<Item>
	) async throws -> [Item] {
		@Sendable
		func fetchAllPaginatedItems(
			collectedResources: PaginatedResourceResponse<Item>?
		) async throws -> [Item] {
			/// Finish when some items where loaded and the nextPageCursor is nil.
			if let collectedResources, collectedResources.cursor == nil {
				return collectedResources.loadedItems
			}

			/// We can request here with nil nextPageCursor, as the first page will not have a cursor.
			let response = try await paginatedRequest(collectedResources?.cursor)
			let oldItems = collectedResources?.loadedItems ?? []
			let allItems = oldItems + response.loadedItems

			let nextPageCursor: PageCursor? = {
				// Safeguard: Don't rely only on the gateway returning nil for the next page cursor,
				// if happened to load an empty page, or all items were loaded - next page cursor is nil.
				if response.loadedItems.isEmpty || allItems.count == response.totalCount.map(Int.init) {
					return nil
				}

				return response.cursor
			}()

			let result = PaginatedResourceResponse(loadedItems: allItems, totalCount: response.totalCount, cursor: nextPageCursor)
			return try await fetchAllPaginatedItems(collectedResources: result)
		}

		return try await fetchAllPaginatedItems(
			collectedResources: cursor.map {
				PaginatedResourceResponse(loadedItems: [], totalCount: nil, cursor: $0)
			}
		)
	}
}

extension AccountPortfoliosClient {
	@Sendable static func extractBehaviors(assignments: GatewayAPI.ComponentEntityRoleAssignments) -> [AssetBehavior] {
		typealias ParsedName = GatewayAPI.RoleKey.ParsedName

		enum Assigned {
			case none, someone, anyone, unknown
		}

		func findEntry(_ name: GatewayAPI.RoleKey.ParsedName) -> GatewayAPI.ComponentEntityRoleAssignmentEntry? {
			assignments.entries.first { $0.roleKey.parsedName == name }
		}

		func performer(_ name: GatewayAPI.RoleKey.ParsedName) -> Assigned {
			guard let assignment = findEntry(name)?.parsedAssignment else { return .unknown }
			switch assignment {
			case .allowAll: return .anyone
			case .denyAll: return .none
			case .protected, .otherExplicit, .owner: return .someone
			}
		}

		func updaters(_ name: GatewayAPI.RoleKey.ParsedName) -> Assigned {
			guard let updaters = findEntry(name)?.updaterRoles, !updaters.isEmpty else { return .none }

			// Lookup the corresponding assignments, ignoring unknown and empty values
			let updaterAssignments = Set(updaters.compactMap(\.parsedName).compactMap(findEntry).compactMap(\.parsedAssignment))

			if updaterAssignments.isEmpty {
				return .unknown
			} else if updaterAssignments == [.denyAll] {
				return .none
			} else if updaterAssignments.contains(.allowAll) {
				return .anyone
			} else {
				return .someone
			}
		}

		var result: Set<AssetBehavior> = []

		// Withdrawer and depositor areas are checked together, but we look at the performer and updater role types separately
		let movers: Set = [performer(.withdrawer), performer(.depositor)]
		if movers != [.anyone] {
			result.insert(.movementRestricted)
		} else {
			let moverUpdaters: Set = [updaters(.withdrawer), updaters(.depositor)]
			if moverUpdaters.contains(.anyone) {
				result.insert(.movementRestrictableInFutureByAnyone)
			} else if moverUpdaters.contains(.someone) {
				result.insert(.movementRestrictableInFuture)
			}
		}

		// Other names are checked individually, but without distinguishing between the role types
		func addBehavior(for name: GatewayAPI.RoleKey.ParsedName, ifSomeone: AssetBehavior, ifAnyone: AssetBehavior) {
			let either: Set = [performer(name), updaters(name)]
			if either.contains(.anyone) {
				result.insert(ifAnyone)
			} else if either.contains(.someone) {
				result.insert(ifSomeone)
			}
		}

		addBehavior(for: .minter, ifSomeone: .supplyIncreasable, ifAnyone: .supplyIncreasableByAnyone)
		addBehavior(for: .burner, ifSomeone: .supplyDecreasable, ifAnyone: .supplyDecreasableByAnyone)
		addBehavior(for: .recaller, ifSomeone: .removableByThirdParty, ifAnyone: .removableByAnyone)
		addBehavior(for: .freezer, ifSomeone: .freezableByThirdParty, ifAnyone: .freezableByAnyone)
		addBehavior(for: .nonFungibleDataUpdater, ifSomeone: .nftDataChangeable, ifAnyone: .nftDataChangeableByAnyone)

		// If there are no special behaviors, that means it's a "simple asset"
		if result.isEmpty {
			return [.simpleAsset]
		}

		// Finally we make some simplifying substitutions
		func substitute(_ source: Set<AssetBehavior>, with target: AssetBehavior) {
			if result.isSuperset(of: source) {
				result.subtract(source)
				result.insert(target)
			}
		}

		// If supply is both increasable and decreasable, then it's "flexible"
		substitute([.supplyIncreasableByAnyone, .supplyDecreasableByAnyone], with: .supplyFlexibleByAnyone)
		substitute([.supplyIncreasable, .supplyDecreasable], with: .supplyFlexible)

		return result.sorted()
	}
}

extension AccountPortfoliosClient {
	@Sendable static func extractTags(item: GatewayAPI.StateEntityDetailsResponseItem) -> [AssetTag] {
		item.metadata.tags?.compactMap(NonEmptyString.init(rawValue:)).map(AssetTag.init) ?? []
	}
}

extension Array where Element == AccountPortfolio.FungibleResource {
	func sorted() async -> AccountPortfolio.FungibleResources {
		@Dependency(\.gatewaysClient) var gatewaysClient

		var xrdResource: AccountPortfolio.FungibleResource?
		var nonXrdResources: [AccountPortfolio.FungibleResource] = []

		let networkId = await gatewaysClient.getCurrentNetworkID()

		for resource in self {
			let isXRD = try? resource.resourceAddress.isXRD(on: networkId)
			if isXRD == true {
				xrdResource = resource
			} else {
				nonXrdResources.append(resource)
			}
		}

		let sortedNonXrdResources = nonXrdResources.sorted { lhs, rhs in
			if lhs.amount > .zero && rhs.amount > .zero {
				return lhs.amount > rhs.amount // Sort descending by amount
			}
			if lhs.amount != .zero || rhs.amount != .zero {
				return lhs.amount != .zero
			}

			if let lhsSymbol = lhs.symbol, let rhsSymbol = rhs.symbol {
				return lhsSymbol < rhsSymbol // Sort alphabetically by symbol
			}
			if lhs.symbol != nil || rhs.symbol != nil {
				return lhs.symbol != nil
			}

			if let lhsName = lhs.name, let rhsName = rhs.name {
				return lhsName < rhsName // Sort alphabetically by name
			}
			return lhs.resourceAddress.address < rhs.resourceAddress.address // Sort by address
		}

		return .init(xrdResource: xrdResource, nonXrdResources: sortedNonXrdResources)
	}
}

extension Array where Element == AccountPortfolio.NonFungibleResource {
	func sorted() -> AccountPortfolio.NonFungibleResources {
		sorted { lhs, rhs in
			switch (lhs.name, rhs.name) {
			case let (.some(lhsName), .some(rhsName)):
				return lhsName < rhsName
			case (nil, .some):
				return false
			case (.some, nil):
				return true
			default:
				return lhs.resourceAddress.address < rhs.resourceAddress.address
			}
		}
	}
}

extension AccountPortfolio.PoolUnitResources {
	// The fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	fileprivate var fungibleResourceAddresses: [String] {
		radixNetworkStakes.compactMap(\.stakeUnitResource?.resourceAddress.address) +
			poolUnits.map(\.poolUnitResource.resourceAddress.address)
	}

	// The non fungible resources used to build up the pool units.
	// Will be used to filter out those from the general fungible resources list.
	fileprivate var nonFungibleResourceAddresses: [String] {
		radixNetworkStakes.compactMap(\.stakeClaimResource?.resourceAddress.address)
	}
}

// FIXME: Temporary hack to extract the key_image_url, until we have a proper schema
extension GatewayAPI.StateNonFungibleDetailsResponseItem {
	public typealias NFTData = AccountPortfolio.NonFungibleResource.NonFungibleToken.NFTData
	public var details: [NFTData] {
		data?.programmaticJson.dictionary?["fields"]?.array?.compactMap {
			guard let dict = $0.dictionary,
			      let value = dict["value"],
			      let type = dict["kind"]?.string.flatMap(GatewayAPI.MetadataValueType.init),
			      let field = dict["field_name"]?.string.flatMap(NFTData.Field.init),
			      let value = NFTData.Value(type: type, value: value)
			else {
				return nil
			}

			return .init(field: field, value: value)
		} ?? []
	}
}

extension AccountPortfolio.NonFungibleResource.NonFungibleToken.NFTData.Value {
	public init?(type: GatewayAPI.MetadataValueType, value: JSONValue) {
		switch type {
		case .string:
			guard let str = value.string else {
				return nil
			}
			self = .string(str)
		case .url:
			guard let url = value.string.flatMap(URL.init) else {
				return nil
			}
			self = .url(url)
		case .u64:
			guard let u64 = value.uint.map(UInt64.init) else {
				return nil
			}
			self = .u64(u64)
		case .decimal:
			guard let decimal = try? value.string.map(BigDecimal.init(fromString:)) else {
				return nil
			}
			self = .decimal(decimal)
		default:
			return nil
		}
	}
}

// FIXME: these:
/*
 We don't have behaviour icons for "freezer"

 We don't have a role for informationChangeable*

 What to do for areas where we have no (parsed) rule?
 */
