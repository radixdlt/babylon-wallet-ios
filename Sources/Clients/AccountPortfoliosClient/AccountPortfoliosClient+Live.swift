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
		@Dependency(\.gatewayAPIClient) var gatewayAPIClient

		let (rawFungibleResources, rawNonFungibleResources) = try await (
			gatewayAPIClient.fetchAllFungibleResources(rawAccountDetails, ledgerState: ledgerState),
			gatewayAPIClient.fetchAllNonFungibleResources(rawAccountDetails, ledgerState: ledgerState)
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

		return try await rawItems.map {
			try createFungibleResource($0, ledgerState: ledgerState)
		}.sorted()
	}

	@Sendable
	static func createFungibleResource(
		_ resource: GatewayAPI.FungibleResourcesCollectionItemVaultAggregated,
		ledgerState: GatewayAPI.LedgerState
	) throws -> AccountPortfolio.FungibleResource {
		try AccountPortfolio.FungibleResource(
			resourceAddress: .init(validatingAddress: resource.resourceAddress),
			atLedgerState: .init(version: ledgerState.stateVersion, epoch: ledgerState.epoch),
			amount: resource.amount,
			metadata: .init(resource.explicitMetadata)
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

			let additionalItems = try await gatewayAPIClient.fetchAllPaginatedItems(
				cursor: GatewayAPIClient.PageCursor(ledgerState: ledgerState, nextPageCursor: nextPageCursor),
				gatewayAPIClient.fetchEntityNonFungibleResourceIdsPage(
					accountAddress,
					resourceAddress: resource.resourceAddress,
					vaultAddress: vault.vaultAddress
				)
			)

			return firstPageItems + additionalItems
		}

		// Get all user owned nft ids, but do not fetch the related data.
		let nftIDs = try await getAllTokens(resource: resource).map {
			try NonFungibleGlobalId.fromParts(resourceAddress: .init(address: resource.resourceAddress), nonFungibleLocalId: .from(stringFormat: $0))
		}.sorted {
			$0.localId().id < $1.localId().id
		}

		return try AccountPortfolio.NonFungibleResource(
			resourceAddress: .init(validatingAddress: resource.resourceAddress),
			atLedgerState: .init(version: ledgerState.stateVersion, epoch: ledgerState.epoch),
			nonFungibleIds: nftIDs,
			metadata: .init(resource.explicitMetadata)
		)
	}
}

extension GatewayAPI.FungibleResourcesCollectionItemVaultAggregated {
	var amount: RETDecimal {
		// Resources of an account always have one single vault which stores the value.
		guard let resourceVault = vaults.items.first else {
			loggerGlobal.warning("Account Portfolio: \(resourceAddress) does not have any vaults")
			return .zero
		}

		do {
			return try .init(value: resourceVault.amount)
		} catch {
			loggerGlobal.error(
				"Account Portfolio: Failed to parse amount for resource: \(resourceAddress), reason: \(error.localizedDescription)"
			)
			return .zero
		}
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
				xrdVaultBalance: .init(value: xrdStakeVaultBalance),
				metadata: .init(item.explicitMetadata)
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

			let allFungibleResources = try await gatewayAPIClient.fetchAllFungibleResources(item, ledgerState: ledgerState)

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

extension Array where Element == AccountPortfolio.FungibleResource {
	func sorted() async -> AccountPortfolio.FungibleResources {
		@Dependency(\.gatewaysClient) var gatewaysClient

		var xrdResource: AccountPortfolio.FungibleResource?
		var nonXrdResources: [AccountPortfolio.FungibleResource] = []

		let networkId = await gatewaysClient.getCurrentNetworkID()

		for resource in self {
			if resource.resourceAddress.isXRD(on: networkId) {
				xrdResource = resource
			} else {
				nonXrdResources.append(resource)
			}
		}

		let sortedNonXrdResources = nonXrdResources.sorted { lhs, rhs in
			if lhs.amount > .zero, rhs.amount > .zero {
				return lhs.amount > rhs.amount // Sort descending by amount
			}
			if lhs.amount != .zero || rhs.amount != .zero {
				return lhs.amount != .zero
			}

			if let lhsSymbol = lhs.metadata.symbol, let rhsSymbol = rhs.metadata.symbol {
				return lhsSymbol < rhsSymbol // Sort alphabetically by symbol
			}
			if lhs.metadata.symbol != nil || rhs.metadata.symbol != nil {
				return lhs.metadata.symbol != nil
			}

			if let lhsName = lhs.metadata.name, let rhsName = rhs.metadata.name {
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
			switch (lhs.metadata.name, rhs.metadata.name) {
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

// FIXME: these:
/*
 We don't have behaviour icons for "freezer"

 We don't have a role for informationChangeable*

 What to do for areas where we have no (parsed) rule?
 */
