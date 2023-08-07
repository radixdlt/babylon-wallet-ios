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
		let details = try await gatewayAPIClient.fetchResourceDetails(addresses.map(\.address), explicitMetadata: EntityMetadataKey.allCases)
		return try await details.items.parallelMap {
			try await createAccountPortfolio($0, ledgerState: details.ledgerState)
		}
	}

	@Sendable
	static func fetchAccountPortfolio(
		_ accountAddress: AccountAddress
	) async throws -> AccountPortfolio {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let accountDetails = try await gatewayAPIClient.fetchResourceDetails([accountAddress.address], explicitMetadata: EntityMetadataKey.allCases)
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
		// Fetch all fungible resources by requesting additional pages if available
		let fetchAllFungibleResources = {
			guard let firstPage = rawAccountDetails.fungibleResources else {
				return [GatewayAPI.FungibleResourcesCollectionItem]()
			}

			guard let nextPageCursor = firstPage.nextCursor else {
				return firstPage.items
			}

			let additionalItems = try await fetchAllPaginatedItems(
				cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
				fetchAccountFungibleResourcePage(rawAccountDetails.address)
			)

			return firstPage.items + additionalItems
		}

		// Fetch all non-fungible resources by requesting additional pages if available
		let fetchAllNonFungibleResources = {
			guard let firstPage = rawAccountDetails.nonFungibleResources else {
				return [GatewayAPI.NonFungibleResourcesCollectionItem]()
			}

			guard let nextPageCursor = firstPage.nextCursor else {
				return firstPage.items
			}

			let additionalItems = try await fetchAllPaginatedItems(
				cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
				fetchNonFungibleResourcePage(rawAccountDetails.address)
			)

			return firstPage.items + additionalItems
		}

		let (rawFungibleResources, rawNonFungibleResources) = try await (fetchAllFungibleResources(), fetchAllNonFungibleResources())

		let poolUnitResources = try await createPoolUnitResources(
			rawAccountDetails.address,
			rawFungibleResources: rawFungibleResources.compactMap(\.vault),
			rawNonFungibleResources: rawNonFungibleResources.compactMap(\.vault),
			ledgerState: ledgerState
		)

		let filteredRawFungibleResources = rawFungibleResources.filter { rawItem in
			// TODO: Check pool units also
			!poolUnitResources.radixNetworkStakes.contains {
				$0.stakeUnitResource.resourceAddress.address == rawItem.resourceAddress
			} &&
				!poolUnitResources.poolUnits.contains {
					$0.poolUnitResource.resourceAddress.address == rawItem.resourceAddress
				}
		}

		let filteredRawNonFungibleResources = rawNonFungibleResources.filter { rawItem in
			// TODO: Check pool units also
			!poolUnitResources.radixNetworkStakes.contains {
				$0.stakeClaimResource?.resourceAddress.address == rawItem.resourceAddress
			}
		}

		// Build up the resources from the raw items.
		async let fungibleResources = createFungibleResources(rawItems: filteredRawFungibleResources, ledgerState: ledgerState)
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

		let fungibleresources = try await rawItems.asyncMap {
			try await createFungibleResource($0, ledgerState: ledgerState)
		}

		return await fungibleresources.sorted()
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

		let details = try await gatewayAPIClient.getEntityDetails([resource.resourceAddress], [], ledgerState).items.first?.details?.fungible
		let totalSupply = try details.map { try BigDecimal(fromString: $0.totalSupply) }

		let resourceAddress = try ResourceAddress(validatingAddress: resource.resourceAddress)
		let metadata = resource.explicitMetadata

		return AccountPortfolio.FungibleResource(
			resourceAddress: resourceAddress,
			amount: amount,
			divisibility: details?.divisibility,
			name: metadata?.name,
			symbol: metadata?.symbol,
			description: metadata?.description,
			iconURL: metadata?.iconURL,
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
		guard !vaultItems.isEmpty else {
			return []
		}

		let nonFungibleResources = try await vaultItems.parallelMap { resource in
			try await createNonFungibleResource(accountAddress, resource, ledgerState: ledgerState)
		}

		return nonFungibleResources.sorted()
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
					return try AccountPortfolio.NonFungibleResource.NonFungibleToken(
						id: .fromParts(
							resourceAddress: .init(address: resource.resourceAddress),
							nonFungibleLocalId: .from(stringFormat: item.nonFungibleId)
						),
						name: details.name,
						description: nil,
						keyImageURL: details.keyImageURL,
						metadata: [],
						stakeClaimAmount: details.stakeClaim,
						claimEpoch: details.claimEpoch,
						canBeClaimed: UInt64(ledgerState.epoch) >= (details.claimEpoch?.rawValue ?? UInt64.max)
					)
				}

				result.append(contentsOf: tokens)
			}

			return result
		}

		// Load the nftIds from the resource vault
		let tokens = try await tokens(resource: resource)
		let metadata = resource.explicitMetadata

		return try AccountPortfolio.NonFungibleResource(
			resourceAddress: .init(validatingAddress: resource.resourceAddress),
			name: metadata?.name,
			description: metadata?.description,
			iconURL: metadata?.iconURL,
			tokens: tokens
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
		// One Resource Pool created:
		//  - 058959450bc3a7cf2830b4e9a5b968fec987fedb0de8419ab12ceb1964a9a841
		//  - pool_tdx_d_1cnjvq6kzp3rp7lv0ddpglezmt409nct55hegq5wpd89666nv94zmk9
		//  - resource_tdx_d_1thfds4qff7twt8j40smxldrge54sam7py2htaps6cxl278ukmgpekm

		// Two Resources pool created:
		// - ee7c5dd26b5f70e0d990a1e86ea5d6ce94464d5e1c7724a64082518023313d70
		// - pool_tdx_d_1ch8fq2yvwsctvfxevn6wxq7htl9yf2gxh9l0efcvzu2dn4sdcgkqxn
		// - resource_tdx_d_1t4r8h77z2hg09lewjl7dql5vcp3hz6879cd2zpsg5x3sct9034eujr

		let stakeUnitCandidates = rawFungibleResources.filter {
			$0.explicitMetadata?.validator != nil
		}

		let stakeClaimNFTCandidates = rawNonFungibleResources.filter {
			$0.explicitMetadata?.validator != nil
		}

		let poolUnitCandidates = rawFungibleResources.filter {
			$0.explicitMetadata?.pool != nil
		}

		let addressesToValidate = stakeUnitCandidates.compactMap(\.explicitMetadata?.validator?.address) + stakeClaimNFTCandidates.compactMap(\.explicitMetadata?.validator?.address) + poolUnitCandidates.compactMap(\.explicitMetadata?.pool?.address)

		guard !addressesToValidate.isEmpty else {
			return .init(radixNetworkStakes: [], poolUnits: [])
		}

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.gatewaysClient) var gatewaysClient

		let networkId = await gatewaysClient.getCurrentNetworkID()
		let xrdAddress = knownAddresses(networkId: networkId.rawValue).resourceAddresses.xrd.addressString()

		let poolUnitDetails = try await gatewayAPIClient.fetchResourceDetails(
			addressesToValidate,
			explicitMetadata: EntityMetadataKey.allCases,
			ledgerState: ledgerState
		)

		let stakeUnits = try await poolUnitDetails.items.asyncCompactMap { item -> AccountPortfolio.PoolUnitResources.RadixNetworkStake? in
			guard let validatorDetails = item.details?.component?.state?.validatorState else {
				// Consider it not a validtor
				return nil
			}

			let validatorStakeUnitCandidate = stakeUnitCandidates.first {
				$0.explicitMetadata?.validator?.address == item.address
			}

			guard let validatorStakeUnitCandidate else { // having a stake unit is required
				assertionFailure("No stake unit could be matched for the validator declared stake unit address, possibly wrong implementation")
				return nil
			}

			guard validatorDetails.stakeUnitResourceAddress == validatorStakeUnitCandidate.resourceAddress else {
				assertionFailure("Bad stake unit candidate, not declared by the validator")
				return nil
			}

			// xrd balance
			guard let xrdResource = item
				.fungibleResources?
				.items
				.first(where: { $0.resourceAddress == xrdAddress })
			else {
				assertionFailure("A validator didn't contain an xrd resource")
				return nil
			}

			guard let xrdStakeVaultBalance = xrdResource
				.vault?
				.vaults
				.items
				.first(where: { $0.vaultAddress == validatorDetails.stakeXRDVaultAddress })?.amount
			else {
				assertionFailure("Validtor XRD Resource didn't contain the \(validatorDetails.stakeXRDVaultAddress) vault ")
				return nil
			}

			let validator = try AccountPortfolio.PoolUnitResources.RadixNetworkStake.Validator(
				address: .init(validatingAddress: item.address),
				xrdVaultBalance: .init(fromString: xrdStakeVaultBalance),
				name: item.explicitMetadata?.name,
				description: item.explicitMetadata?.description,
				iconURL: item.explicitMetadata?.iconURL
			)

			let stakeUnitFungibleResource = try await createFungibleResource(validatorStakeUnitCandidate, ledgerState: ledgerState)

			let stakeClaimNft: AccountPortfolio.NonFungibleResource? = try await { () -> AccountPortfolio.NonFungibleResource? in
				let stakeClaimNft = stakeClaimNFTCandidates.first {
					$0.explicitMetadata?.validator?.address == item.address
				}

				guard let stakeClaimNft else {
					return nil
				}

				guard validatorDetails.unstakeClaimTokenResourceAddress == stakeClaimNft.resourceAddress else {
					assertionFailure("Bad stake claim nft candidate, not declared by the validator")
					return nil
				}

				return try await createNonFungibleResource(accountAddress, stakeClaimNft, ledgerState: ledgerState)

			}()

			return .init(validator: validator, stakeUnitResource: stakeUnitFungibleResource, stakeClaimResource: stakeClaimNft)
		}

		let poolUnits = try await poolUnitDetails.items.asyncCompactMap { item -> AccountPortfolio.PoolUnitResources.PoolUnit? in
			guard let poolAddress = try? ResourcePoolAddress(validatingAddress: item.address) else {
				return nil
			}

			// create pool unit
			guard let poolUnitResourceAddress = item.explicitMetadata?.poolUnitResource else {
				assertionFailure("Pool Unit does not contain the pool unit resource address")
				return nil
			}

			let poolUnitResourceCandidate = poolUnitCandidates.first {
				$0.explicitMetadata?.pool == poolAddress
			}

			guard let poolUnitResourceCandidate else {
				assertionFailure("No pool unit could candidate be matched for the pool unit declared pool unit address, possibly wrong implementation")
				return nil
			}

			guard poolUnitResourceCandidate.resourceAddress == poolUnitResourceAddress.address else {
				assertionFailure("Bad stake pool unit address candidate, not declared by the pool unit")
				return nil
			}

			guard let poolUnitResources = item.fungibleResources else {
				assertionFailure("Empty Pool Unit!!!")
				return nil
			}

			let allFungibleResources = try await {
				guard let nextPageCursor = poolUnitResources.nextCursor else {
					return poolUnitResources.items
				}

				let additionalItems = try await fetchAllPaginatedItems(
					cursor: PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
					fetchAccountFungibleResourcePage(poolAddress.address)
				)

				return poolUnitResources.items + additionalItems
			}()

			let resources = try await createFungibleResources(rawItems: allFungibleResources, ledgerState: ledgerState)
			let poolUnitResource = try await createFungibleResource(poolUnitResourceCandidate, ledgerState: ledgerState)
			return .init(
				pool: .init(address: poolAddress, name: item.explicitMetadata?.name, description: item.explicitMetadata?.description, iconURL: item.explicitMetadata?.iconURL),
				poolUnitResource: poolUnitResource,
				poolResources: resources
			)
		}

		return .init(radixNetworkStakes: stakeUnits, poolUnits: poolUnits)
	}
}

// MARK: - Endpoints
extension AccountPortfoliosClient {
	static func fetchAccountFungibleResourcePage(
		_ accountAddress: String
	) -> @Sendable (PageCursor?) async throws -> PaginatedResourceResponse<GatewayAPI.FungibleResourcesCollectionItem> {
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		return { pageCursor in
			let request = GatewayAPI.StateEntityFungiblesPageRequest(
				atLedgerState: pageCursor?.ledgerState.selector,
				cursor: pageCursor?.nextPageCursor,
				address: accountAddress,
				aggregationLevel: .global
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
