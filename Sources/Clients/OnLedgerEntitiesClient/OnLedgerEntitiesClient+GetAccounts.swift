import Foundation
import GatewayAPI
import SharedModels

extension OnLedgerEntitiesClient {
	@Sendable
	static func createAccount(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		accountAddress: AccountAddress,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.Account {
		let fungibleResources = try extractOwnedFungibleResources(item, ledgerState: ledgerState)
		let nonFungibleResources = try extractOwnedNonFungibleResources(item, ledgerState: ledgerState)

		let poolUnitResources = try await createPoolUnitResources(
			accountAddress.address,
			rawFungibleResources: fungibleResources,
			rawNonFungibleResources: nonFungibleResources,
			ledgerState: ledgerState
		)

		let filteredFungibleResources = fungibleResources.filter { resource in
			!poolUnitResources.fungibleResourceAddresses.contains(resource.resourceAddress.address)
		}

		let filteredNonFungibleResources = nonFungibleResources.filter { resource in
			!poolUnitResources.nonFungibleResourceAddresses.contains(resource.resourceAddress.address)
		}

		return await .init(
			address: accountAddress,
			atLedgerState: ledgerState,
			metadata: .init(item.explicitMetadata),
			fungibleResources: filteredFungibleResources.sorted(),
			nonFungibleResources: filteredNonFungibleResources,
			poolUnitResources: poolUnitResources
		)
	}

	@Sendable
	static func createResourcePool(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		resourcePoolAddress: ResourcePoolAddress,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.ResourcePool? {
		guard let state: GatewayAPI.ResourcePoolState = try? item.details?.component?.decodeState() else {
			assertionFailure("Invalid resource pool state")
			return nil
		}

		return try await .init(
			address: resourcePoolAddress,
			poolUnitResourceAddress: .init(validatingAddress: state.poolUnitResourceAddress),
			resources: extractOwnedFungibleResources(item, ledgerState: ledgerState).sorted(),
			metadata: .init(item.explicitMetadata)
		)
	}

	@Sendable
	static func createValidator(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		validatorAddress: ValidatorAddress,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.Validator? {
		@Dependency(\.gatewaysClient) var gatewaysClient
		let networkId = await gatewaysClient.getCurrentNetworkID()
		let xrdAddress = knownAddresses(networkId: networkId.rawValue).resourceAddresses.xrd.addressString()

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

		return try .init(
			address: validatorAddress,
			stakeUnitResourceAddress: .init(validatingAddress: state.stakeUnitResourceAddress),
			xrdVaultBalance: .init(value: xrdStakeVaultBalance),
			stakeClaimFungibleResourceAddress: .init(validatingAddress: state.unstakeClaimTokenResourceAddress),
			metadata: .init(item.explicitMetadata)
		)
	}

	static func extractOwnedFungibleResources(_ item: GatewayAPI.StateEntityDetailsResponseItem, ledgerState: AtLedgerState) throws -> [OnLedgerEntity.OwnedFungibleResource] {
		try item.fungibleResources?.items.compactMap(\.vault).compactMap { vaultAggregated -> OnLedgerEntity.OwnedFungibleResource? in
			guard let vault = vaultAggregated.vaults.items.first else {
				assertionFailure("Onwed resources without vault???")
				return nil
			}

			return try .init(
				resourceAddress: .init(validatingAddress: vaultAggregated.resourceAddress),
				atLedgerState: ledgerState,
				amount: .init(value: vault.amount),
				metadata: .init(vaultAggregated.explicitMetadata)
			)
		} ?? []
	}

	static func extractOwnedNonFungibleResources(_ item: GatewayAPI.StateEntityDetailsResponseItem, ledgerState: AtLedgerState) throws -> [OnLedgerEntity.OwnedNonFungibleResource] {
		try item.nonFungibleResources?.items.compactMap(\.vault).compactMap { vaultAggregated -> OnLedgerEntity.OwnedNonFungibleResource? in
			guard let vault = vaultAggregated.vaults.items.first else {
				assertionFailure("Onwed resources without vault???")
				return nil
			}
			return try .init(
				resourceAddress: .init(validatingAddress: vaultAggregated.resourceAddress),
				atLedgerState: ledgerState,
				metadata: .init(vaultAggregated.explicitMetadata),
				nonFungibleIdsCount: Int(vault.totalCount),
				vaultAddress: .init(validatingAddress: vault.vaultAddress)
			)
		}.sorted() ?? []
	}

	@Sendable
	static func createPoolUnitResources(
		_ accountAddress: String,
		rawFungibleResources: [OnLedgerEntity.OwnedFungibleResource],
		rawNonFungibleResources: [OnLedgerEntity.OwnedNonFungibleResource],
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.Account.PoolUnitResources {
		let stakeUnitCandidates = rawFungibleResources.filter {
			$0.metadata.validator != nil
		}

		let stakeClaimNFTCandidates = rawNonFungibleResources.filter {
			$0.metadata.validator != nil
		}

		let poolUnitCandidates = rawFungibleResources.filter {
			$0.metadata.poolUnit != nil
		}

		func matchPoolUnitCandidate(
			for poolUnitResourceAddress: ResourceAddress,
			itemAddress: Address,
			candidates: [OnLedgerEntity.OwnedFungibleResource],
			metadataAddressMatch: KeyPath<ResourceMetadata, String?>
		) -> OnLedgerEntity.OwnedFungibleResource? {
			guard let candidate = candidates.first(where: {
				$0.metadata[keyPath: metadataAddressMatch] == itemAddress.address
			}) else {
				return nil
			}

			guard candidate.resourceAddress.address == poolUnitResourceAddress.address else {
				assertionFailure("Bad candidate, not declared by the pool unit")
				return nil
			}

			return candidate
		}

		let stakeAndPoolAddresses = stakeUnitCandidates.compactMap(\.metadata.validator?.address)
			+ stakeClaimNFTCandidates.compactMap(\.metadata.validator?.address)
			+ poolUnitCandidates.compactMap(\.metadata.poolUnit?.address)

		guard !stakeAndPoolAddresses.isEmpty else {
			return .init(radixNetworkStakes: [], poolUnits: [])
		}

		let entities = try await getEntities(
			for: stakeAndPoolAddresses,
			.poolUnitMetadataKeys,
			ledgerState: ledgerState
		)
		let validators = entities.compactMap(\.validator)
		let resourcesPools = entities.compactMap(\.resourcePool)

		let stakeUnits = validators.compactMap { validator -> OnLedgerEntity.Account.RadixNetworkStake? in
			let stakeUnit = matchPoolUnitCandidate(
				for: validator.stakeUnitResourceAddress,
				itemAddress: validator.address.asGeneral(),
				candidates: stakeUnitCandidates,
				metadataAddressMatch: \.validator?.address
			)

			let stakeClaimNFT: OnLedgerEntity.OwnedNonFungibleResource? = {
				let stakeClaimNFTCandidate = stakeClaimNFTCandidates.first {
					$0.metadata.validator == validator.address
				}

				guard let stakeClaimNFTCandidate else {
					return nil
				}

				// Then validate that the validator is also referencing the candidate
				guard validator.stakeClaimFungibleResourceAddress == stakeClaimNFTCandidate.resourceAddress else {
					assertionFailure("Bad stake claim nft candidate, not declared by the validator")
					return nil
				}

				return stakeClaimNFTCandidate
			}()

			if stakeUnit != nil || stakeClaimNFT != nil {
				return .init(
					validatorAddress: validator.address,
					stakeUnitResource: stakeUnit,
					stakeClaimResource: stakeClaimNFT
				)
			}

			return nil
		}

		let poolUnits = resourcesPools.compactMap { pool -> OnLedgerEntity.Account.PoolUnit? in
			let poolUnitResource = matchPoolUnitCandidate(
				for: pool.poolUnitResourceAddress,
				itemAddress: pool.address.asGeneral(),
				candidates: poolUnitCandidates,
				metadataAddressMatch: \.poolUnit?.address
			)

			guard let poolUnitResource else {
				assertionFailure("Pool Unit not matched by any candidate")
				return nil
			}

			return OnLedgerEntity.Account.PoolUnit(resource: poolUnitResource, resourcePoolAddress: pool.address)
		}

		return .init(radixNetworkStakes: stakeUnits, poolUnits: poolUnits)
	}

	@Sendable
	public func getPoolUnitsDetail(_ ownedPoolUnits: [OnLedgerEntity.Account.PoolUnit]) async throws -> [OnLedgerEntity.ResourcePoolDetails] {
		let pools = try await getEntities(ownedPoolUnits.map { $0.resourcePoolAddress.asGeneral() }, [], nil).compactMap(\.resourcePool)
		let allResourceAddresses = pools.flatMap { pool in
			[pool.poolUnitResourceAddress] +
				pool.resources.nonXrdResources.map(\.resourceAddress) +
				(pool.resources.xrdResource.map { [$0.resourceAddress] } ?? [])
		}

		let allResources = try await getResources(allResourceAddresses, atLedgerState: nil)

		return ownedPoolUnits.compactMap { ownedPoolUnit -> OnLedgerEntity.ResourcePoolDetails? in
			guard let pool = pools.first(where: { $0.address == ownedPoolUnit.resourcePoolAddress }) else {
				assertionFailure("Did not load pool details")
				return nil
			}
			guard let poolUnitResource = allResources.first(where: { $0.resourceAddress == pool.poolUnitResourceAddress }) else {
				assertionFailure("Did not load poolUnitResource details")
				return nil
			}

			var nonXrdResourceDetails: [OnLedgerEntity.ResourceWithVaultAmount] = []

			for resource in pool.resources.nonXrdResources {
				guard let resourceDetails = allResources.first(where: { $0.resourceAddress == resource.resourceAddress }) else {
					assertionFailure("Did not load resource details")
					return nil
				}
				nonXrdResourceDetails.append(.init(resource: resourceDetails, amount: resource.amount))
			}

			var xrdResourceDetails: OnLedgerEntity.ResourceWithVaultAmount? = nil
			if let xrdResource = pool.resources.xrdResource {
				guard let details = allResources.first(where: { $0.resourceAddress == xrdResource.resourceAddress }) else {
					assertionFailure("Did not load xrd resource details")
					return nil
				}
				xrdResourceDetails = .init(resource: details, amount: xrdResource.amount)
			}

			return .init(
				address: pool.address,
				poolUnitResource: .init(resource: poolUnitResource, amount: ownedPoolUnit.resource.amount),
				xrdResource: xrdResourceDetails,
				nonXrdResources: nonXrdResourceDetails
			)
		}
	}

	public func getValidatorsDetails(account: OnLedgerEntity.Account, _ ownedStakes: [OnLedgerEntity.Account.RadixNetworkStake]) async throws -> [OnLedgerEntity.ValidatorDetails] {
		let validators = try await getEntities(ownedStakes.map { $0.validatorAddress.asGeneral() }, .resourceMetadataKeys, account.atLedgerState).compactMap(\.validator)
		let resourceAddresses = ownedStakes.flatMap {
			$0.stakeUnitResource.asArray(\.resourceAddress) + $0.stakeClaimResource.asArray(\.resourceAddress)
		}

		let resourceDetails = try await getResources(resourceAddresses, atLedgerState: account.atLedgerState)

		return try await ownedStakes.asyncCompactMap { stake -> OnLedgerEntity.ValidatorDetails? in
			guard let validatorDetails = validators.first(where: { $0.address == stake.validatorAddress }) else {
				assertionFailure("Did not load validator details")
				return nil
			}

			let stakeUnitResource: OnLedgerEntity.ResourceWithVaultAmount? = {
				if let stakeUnitResource = stake.stakeUnitResource {
					guard let stakeUnitDetails = resourceDetails.first(where: { $0.resourceAddress == stakeUnitResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						return nil
					}
					return .init(resource: stakeUnitDetails, amount: stakeUnitResource.amount)
				}

				return nil
			}()

			let stakeClaimTokens: OnLedgerEntity.NonFunbileResourceWithTokens? = try await {
				if let stakeClaimResource = stake.stakeClaimResource {
					guard let stakeClaimResourceDetails = resourceDetails.first(where: { $0.resourceAddress == stakeClaimResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						return nil
					}
					let tokenData = try await getAccountOwnedNonFungibleTokenData(.init(accountAddress: account.address, resource: stakeClaimResource))
					return .init(resource: stakeClaimResourceDetails, tokens: tokenData)
				}

				return nil
			}()

			return .init(
				validator: validatorDetails,
				stakeUnitResource: stakeUnitResource,
				stakeClaimTokens: stakeClaimTokens
			)
		}
	}
}

extension Optional {
	func asArray<T>(_ keyPath: KeyPath<Wrapped, T>) -> [T] {
		if let wrapped = self {
			return [wrapped[keyPath: keyPath]]
		}
		return []
	}
}

extension OnLedgerEntity {
	public struct ValidatorDetails: Hashable, Sendable {
		public let validator: OnLedgerEntity.Validator
		public let stakeUnitResource: ResourceWithVaultAmount?
		public let stakeClaimTokens: NonFunbileResourceWithTokens?
	}

	public struct ResourcePoolDetails: Hashable, Sendable {
		public let address: ResourcePoolAddress
		public let poolUnitResource: ResourceWithVaultAmount
		public let xrdResource: ResourceWithVaultAmount?
		public let nonXrdResources: [ResourceWithVaultAmount]
	}

	public struct ResourceWithVaultAmount: Hashable, Sendable {
		public let resource: OnLedgerEntity.Resource
		public let amount: RETDecimal
	}

	public struct NonFunbileResourceWithTokens: Hashable, Sendable {
		public let resource: OnLedgerEntity.Resource
		public let tokens: [OnLedgerEntity.NonFungibleToken]
	}
}

extension Array where Element == OnLedgerEntity.OwnedFungibleResource {
	func sorted() async -> OnLedgerEntity.OwnedFungibleResources {
		@Dependency(\.gatewaysClient) var gatewaysClient

		var xrdResource: OnLedgerEntity.OwnedFungibleResource?
		var nonXrdResources: [OnLedgerEntity.OwnedFungibleResource] = []

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

extension Array where Element == OnLedgerEntity.OwnedNonFungibleResource {
	func sorted() -> [OnLedgerEntity.OwnedNonFungibleResource] {
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
