import Sargon

extension OnLedgerEntitiesClient {
	@Sendable
	static func createEntity(
		from item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity? {
		let address = try Address(validatingAddress: item.address)

		switch address {
		case let .account(accountAddress):
			return try await .account(
				createAccount(
					address: accountAddress,
					item,
					ledgerState: ledgerState
				)
			)

		case let .resource(resourceAddress):
			return createResource(
				address: resourceAddress,
				item,
				ledgerState: ledgerState
			).map(OnLedgerEntity.resource)

		case let .pool(poolAddress):
			guard let resourcePool = try await createResourcePool(
				address: poolAddress,
				item,
				ledgerState: ledgerState
			) else {
				return nil
			}

			return .resourcePool(resourcePool)

		case let .validator(validatorAddress):
			guard let validator = try await createValidator(
				address: validatorAddress,
				item,
				ledgerState: ledgerState
			) else {
				return nil
			}
			return .validator(validator)

		case let .locker(lockerAddress):
			return try .locker(createLocker(item, ledgerState: ledgerState))

		default:
			return try .genericComponent(createGenericComponent(item, ledgerState: ledgerState))
		}
	}

	@Sendable
	static func createAccount(
		address accountAddress: AccountAddress,
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.OnLedgerAccount {
		let fungibleResources = try extractOwnedFungibleResources(item, ledgerState: ledgerState)
		let nonFungibleResources = try extractOwnedNonFungibleResources(item, ledgerState: ledgerState)

		let poolUnitResources = try await createPoolUnitResources(
			address: accountAddress,
			rawFungibleResources: fungibleResources,
			rawNonFungibleResources: nonFungibleResources,
			ledgerState: ledgerState
		)

		let filteredFungibleResources = fungibleResources.filter { resource in
			!poolUnitResources.fungibleResourceAddresses.contains(resource.resourceAddress)
		}

		let filteredNonFungibleResources = nonFungibleResources.filter { resource in
			!poolUnitResources.nonFungibleResourceAddresses.contains(resource.resourceAddress)
		}

		return await .init(
			address: accountAddress,
			atLedgerState: ledgerState,
			metadata: .init(item.metadata),
			fungibleResources: filteredFungibleResources.sorted(),
			nonFungibleResources: filteredNonFungibleResources.sorted(),
			poolUnitResources: poolUnitResources,
			details: OnLedgerEntity.OnLedgerAccount.Details(item.details)
		)
	}

	@Sendable
	static func createLocker(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) throws -> OnLedgerEntity.Locker {
		try .init(
			address: .init(validatingAddress: item.address),
			atLedgerState: ledgerState,
			metadata: .init(item.metadata)
		)
	}

	@Sendable
	static func createGenericComponent(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) throws -> OnLedgerEntity.GenericComponent {
		try .init(
			address: .init(validatingAddress: item.address),
			atLedgerState: ledgerState,
			behaviors: item.details?.component?.roleAssignments?.extractBehaviors() ?? [],
			metadata: .init(item.metadata)
		)
	}

	@Sendable
	static func createResource(
		address resourceAddress: ResourceAddress,
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) -> OnLedgerEntity.Resource? {
		switch item.details {
		case let .fungibleResource(fungibleDetails):
			.init(
				resourceAddress: resourceAddress,
				atLedgerState: ledgerState,
				divisibility: UInt8(fungibleDetails.divisibility),
				behaviors: item.details?.fungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? Decimal192(fungibleDetails.totalSupply),
				metadata: .init(item.metadata)
			)
		case let .nonFungibleResource(nonFungibleDetails):
			.init(
				resourceAddress: resourceAddress,
				atLedgerState: ledgerState,
				divisibility: nil,
				behaviors: item.details?.nonFungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? Decimal192(nonFungibleDetails.totalSupply),
				metadata: .init(item.metadata)
			)
		default:
			nil
		}
	}

	@Sendable
	static func createResourcePool(
		address poolAddress: PoolAddress,
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.ResourcePool? {
		guard let state: GatewayAPI.ResourcePoolState = try? item.details?.component?.decodeState() else {
			assertionFailure("Invalid resource pool state")
			return nil
		}

		return try await .init(
			address: poolAddress,
			poolUnitResourceAddress: .init(validatingAddress: state.poolUnitResourceAddress),
			resources: extractOwnedFungibleResources(item, ledgerState: ledgerState).sorted(),
			metadata: .init(item.metadata)
		)
	}

	@Sendable
	static func createValidator(
		address validatorAddress: ValidatorAddress,
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.Validator? {
		@Dependency(\.gatewaysClient) var gatewaysClient
		let networkId = await gatewaysClient.getCurrentNetworkID()
		let xrdAddress: ResourceAddress = .xrd(on: networkId)

		guard let state: GatewayAPI.ValidatorState = try? item.details?.component?.decodeState() else {
			assertionFailure("Invalid validator state")
			return nil
		}

		// Get the validator XRD resource
		guard let xrdResource = item
			.fungibleResources?
			.items
			.first(where: { $0.resourceAddress == xrdAddress.address })
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
			assertionFailure("Validator XRD Resource didn't contain the \(state.stakeXRDVaultAddress) vault ")
			return nil
		}

		return try .init(
			address: validatorAddress,
			stakeUnitResourceAddress: .init(validatingAddress: state.stakeUnitResourceAddress),
			xrdVaultBalance: Decimal192(xrdStakeVaultBalance),
			stakeClaimFungibleResourceAddress: .init(validatingAddress: state.unstakeClaimTokenResourceAddress),
			metadata: .init(item.metadata)
		)
	}

	@Sendable
	static func createPoolUnitResources(
		address accountAddress: AccountAddress,
		rawFungibleResources: [OnLedgerEntity.OwnedFungibleResource],
		rawNonFungibleResources: [OnLedgerEntity.OwnedNonFungibleResource],
		ledgerState: AtLedgerState,
		cachingStrategy: CachingStrategy = .useCache
	) async throws -> OnLedgerEntity.OnLedgerAccount.PoolUnitResources {
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
			metadataAddressMatch: KeyPath<OnLedgerEntity.Metadata, String?>
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

		let stakeAndPoolAddresses = Set(
			stakeUnitCandidates.compactMap(\.metadata.validator).map(\.asGeneral)
				+ stakeClaimNFTCandidates.compactMap(\.metadata.validator).map(\.asGeneral)
				+ poolUnitCandidates.compactMap(\.metadata.poolUnit).map(\.asGeneral)
		)

		guard !stakeAndPoolAddresses.isEmpty else {
			return .init(radixNetworkStakes: [], poolUnits: [])
		}

		let entities = try await getEntities(
			for: Array(stakeAndPoolAddresses),
			optIns: .init(explicitMetadata: Set<EntityMetadataKey>.resourceMetadataKeys.map(\.rawValue)),
			ledgerState: ledgerState,
			cachingStrategy: cachingStrategy,
			fetchMetadata: false
		)
		let validators = entities.compactMap(\.validator)
		let resourcesPools = entities.compactMap(\.resourcePool)

		let stakeUnits = validators.compactMap { validator -> OnLedgerEntity.OnLedgerAccount.RadixNetworkStake? in
			let stakeUnit = matchPoolUnitCandidate(
				for: validator.stakeUnitResourceAddress,
				itemAddress: validator.address.asGeneral,
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

		let poolUnits = resourcesPools.compactMap { pool -> OnLedgerEntity.OnLedgerAccount.PoolUnit? in
			let poolUnitResource = matchPoolUnitCandidate(
				for: pool.poolUnitResourceAddress,
				itemAddress: pool.address.asGeneral,
				candidates: poolUnitCandidates,
				metadataAddressMatch: \.poolUnit?.address
			)

			guard let poolUnitResource else {
				assertionFailure("Pool Unit not matched by any candidate")
				return nil
			}

			return OnLedgerEntity.OnLedgerAccount.PoolUnit(resource: poolUnitResource, resourcePoolAddress: pool.address)
		}

		let poolUnitResources = OnLedgerEntity.OnLedgerAccount.PoolUnitResources(radixNetworkStakes: stakeUnits.asIdentified(), poolUnits: poolUnits.sorted())
		return poolUnitResources
	}

	static func extractOwnedFungibleResources(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) throws -> [OnLedgerEntity.OwnedFungibleResource] {
		try item.fungibleResources?.items.compactMap(\.vault).compactMap { vaultAggregated -> OnLedgerEntity.OwnedFungibleResource? in
			guard let vault = vaultAggregated.vaults.items.first else {
				assertionFailure("Owned resource without a vault???")
				return nil
			}

			let amount = try Decimal192(vault.amount)
			return try .init(
				resourceAddress: .init(validatingAddress: vaultAggregated.resourceAddress),
				atLedgerState: ledgerState,
				amount: .exact(amount),
				metadata: .init(vaultAggregated.explicitMetadata)
			)
		} ?? []
	}

	static func extractOwnedNonFungibleResources(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) throws -> [OnLedgerEntity.OwnedNonFungibleResource] {
		try item.nonFungibleResources?.items.compactMap(\.vault).compactMap { vaultAggregated -> OnLedgerEntity.OwnedNonFungibleResource? in
			guard let vault = vaultAggregated.vaults.items.first else {
				assertionFailure("Owned resource without a vault???")
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
}

extension OnLedgerEntitiesClient {
	/// This loads all of the related stake unit details required by the Pool Units screen.
	/// We don't do any pagination there(yet), since the number of owned stakes will not be big, this can be revised in the future.
	func getOwnedStakesDetails(
		account: OnLedgerEntity.OnLedgerAccount,
		cachingStrategy: CachingStrategy = .useCache
	) async throws -> [OwnedStakeDetails] {
		let ownedStakes = account.poolUnitResources.radixNetworkStakes
		let validators = try await getEntities(
			addresses: ownedStakes.map(\.validatorAddress).map(\.asGeneral),
			metadataKeys: .resourceMetadataKeys,
			cachingStrategy: cachingStrategy,
			atLedgerState: account.atLedgerState
		).compactMap(\.validator)

		let resourceAddresses = ownedStakes.flatMap {
			$0.stakeUnitResource.asArray(\.resourceAddress) + $0.stakeClaimResource.asArray(\.resourceAddress)
		}

		let resourceDetails = try await getResources(
			resourceAddresses,
			cachingStrategy: cachingStrategy,
			atLedgerState: account.atLedgerState
		)

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		let currentEpoch = try await gatewayAPIClient.getEpoch()

		let allStakeClaimTokens = try await ownedStakes.compactMap { validator -> (ValidatorAddress, OnLedgerEntity.OwnedNonFungibleResource)? in
			guard let stakeClaimResource = validator.stakeClaimResource else {
				return nil
			}

			return (validator.validatorAddress, stakeClaimResource)
		}
		.parallelMap { validatorAddress, stakeClaimResource -> (ValidatorAddress, [OnLedgerEntity.NonFungibleToken]) in
			let tokens = try await getAccountOwnedNonFungibleTokenData(.init(
				accountAddress: account.address,
				resource: stakeClaimResource,
				mode: .loadAll
			)).tokens

			return (validatorAddress, tokens)
		}

		return try await ownedStakes.asyncCompactMap { stake -> OwnedStakeDetails? in
			guard let validatorDetails = validators.first(where: { $0.address == stake.validatorAddress }) else {
				assertionFailure("Did not load validator details")
				return nil
			}

			let stakeUnitResource: ResourceWithVaultAmount? = {
				if let stakeUnitResource = stake.stakeUnitResource {
					guard let stakeUnitDetails = resourceDetails.first(where: { $0.resourceAddress == stakeUnitResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						fatalError()
					}
					return .init(
						resource: stakeUnitDetails,
						amount: stakeUnitResource.amount
					)
				}

				return nil
			}()

			let stakeClaimTokens: NonFungibleResourceWithTokens? = { () -> NonFungibleResourceWithTokens? in
				if let stakeClaimResource = stake.stakeClaimResource, stakeClaimResource.nonFungibleIdsCount > 0 {
					guard let stakeClaimResourceDetails = resourceDetails.first(where: { $0.resourceAddress == stakeClaimResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						return nil
					}

					return .init(
						resource: stakeClaimResourceDetails,
						stakeClaims: (allStakeClaimTokens.first { $0.0 == stake.validatorAddress }?.1 ?? []).compactMap { token -> OnLedgerEntitiesClient.StakeClaim? in
							guard
								let claimEpoch = token.data?.claimEpoch,
								let claimAmount = token.data?.claimAmount,
								claimAmount > 0
							else {
								return nil
							}

							return OnLedgerEntitiesClient.StakeClaim(
								validatorAddress: stake.validatorAddress,
								token: token,
								claimAmount: .init(nominalAmount: claimAmount),
								reamainingEpochsUntilClaim: Int(claimEpoch) - Int(currentEpoch)
							)
						}.asIdentified()
					)
				}

				return nil
			}()

			return .init(
				validator: validatorDetails,
				stakeUnitResource: stakeUnitResource,
				stakeClaimTokens: stakeClaimTokens,
				currentEpoch: currentEpoch
			)
		}
	}
}

extension OnLedgerEntity.OnLedgerAccount.PoolUnitResources {
	var nonEmptyVaults: OnLedgerEntity.OnLedgerAccount.PoolUnitResources {
		let stakes = radixNetworkStakes.compactMap { stake in
			let stakeUnitResource: OnLedgerEntity.OwnedFungibleResource? = {
				guard
					let stakeUnitResource = stake.stakeUnitResource,
					let amount = stakeUnitResource.amount.exactAmount,
					amount.nominalAmount > 0
				else {
					return nil
				}
				return stakeUnitResource
			}()

			let stakeClaimNFT: OnLedgerEntity.OwnedNonFungibleResource? = {
				guard let stakeClaimNFT = stake.stakeClaimResource, stakeClaimNFT.nonFungibleIdsCount > 0 else {
					return nil
				}
				return stakeClaimNFT
			}()

			if stakeUnitResource != nil || stakeClaimNFT != nil {
				return OnLedgerEntity.OnLedgerAccount.RadixNetworkStake(
					validatorAddress: stake.validatorAddress,
					stakeUnitResource: stakeUnitResource,
					stakeClaimResource: stakeClaimNFT
				)
			}
			return nil
		}

		let poolUnits = poolUnits.filter {
			guard let amount = $0.resource.amount.exactAmount else { return false }
			return amount > .zero
		}

		return .init(radixNetworkStakes: stakes.asIdentified(), poolUnits: poolUnits)
	}
}

extension [OnLedgerEntity.OwnedNonFungibleResource] {
	var nonEmptyVaults: [OnLedgerEntity.OwnedNonFungibleResource] {
		filter { $0.nonFungibleIdsCount > 0 }
	}
}

extension OnLedgerEntity.OwnedFungibleResources {
	var nonEmptyVaults: OnLedgerEntity.OwnedFungibleResources {
		.init(
			xrdResource: xrdResource.flatMap {
				guard let amount = $0.amount.exactAmount, amount.nominalAmount > 0 else {
					return nil
				}
				return $0
			},
			nonXrdResources: nonXrdResources.filter {
				guard let amount = $0.amount.exactAmount else { return false }
				return amount.nominalAmount > 0
			}
		)
	}
}

extension OnLedgerEntity.OnLedgerAccount {
	var nonEmptyVaults: OnLedgerEntity.OnLedgerAccount {
		.init(
			address: address,
			atLedgerState: atLedgerState,
			metadata: metadata,
			fungibleResources: fungibleResources.nonEmptyVaults,
			nonFungibleResources: nonFungibleResources.nonEmptyVaults,
			poolUnitResources: poolUnitResources.nonEmptyVaults,
			details: details
		)
	}
}

extension OnLedgerEntitiesClient {
	struct OwnedStakeDetails: Hashable, Sendable {
		let validator: OnLedgerEntity.Validator
		var stakeUnitResource: ResourceWithVaultAmount?
		var stakeClaimTokens: NonFungibleResourceWithTokens?
		let currentEpoch: Epoch
	}

	struct OwnedResourcePoolDetails: Hashable, Sendable {
		let address: PoolAddress
		let dAppName: String?
		let poolUnitResource: ResourceWithVaultAmount
		var xrdResource: ResourceWithRedemptionValue?
		var nonXrdResources: [ResourceWithRedemptionValue]

		struct ResourceWithRedemptionValue: Hashable, Sendable {
			let resource: OnLedgerEntity.Resource
			var redemptionValue: ResourceAmount?
		}
	}

	struct ResourceWithVaultAmount: Hashable, Sendable {
		let resource: OnLedgerEntity.Resource
		var amount: ResourceAmount
	}

	struct StakeClaim: Hashable, Sendable, Identifiable {
		var id: NonFungibleGlobalId {
			token.id
		}

		let validatorAddress: ValidatorAddress
		let token: OnLedgerEntity.NonFungibleToken
		var claimAmount: ExactResourceAmount
		let reamainingEpochsUntilClaim: Int?

		var isReadyToBeClaimed: Bool {
			guard let reamainingEpochsUntilClaim else { return false }
			return reamainingEpochsUntilClaim <= .zero
		}

		var isUnstaking: Bool {
			guard let reamainingEpochsUntilClaim else { return false }
			return reamainingEpochsUntilClaim > .zero
		}

		var isToBeClaimed: Bool {
			reamainingEpochsUntilClaim == nil
		}
	}

	struct NonFungibleResourceWithTokens: Hashable, Sendable {
		let resource: OnLedgerEntity.Resource
		var stakeClaims: IdentifiedArrayOf<StakeClaim>
	}
}

extension OnLedgerEntity.Metadata {
	var title: String? {
		symbol ?? name
	}
}

extension [OnLedgerEntity.OwnedFungibleResource] {
	func sorted() async -> OnLedgerEntity.OwnedFungibleResources {
		@Dependency(\.gatewaysClient) var gatewaysClient

		var xrdResource: OnLedgerEntity.OwnedFungibleResource?
		var nonXrdResources: [OnLedgerEntity.OwnedFungibleResource] = []

		let networkId = await gatewaysClient.getCurrentNetworkID()

		for resource in self {
			if resource.resourceAddress.isXRD(on: networkId) {
				xrdResource = resource
				precondition(resource.resourceAddress.isXRD)
			} else {
				nonXrdResources.append(resource)
			}
		}

		let sortedNonXrdResources = nonXrdResources.sorted(by: <)

		return .init(xrdResource: xrdResource, nonXrdResources: sortedNonXrdResources)
	}
}

// MARK: - OnLedgerEntity.OwnedFungibleResource + Comparable
extension OnLedgerEntity.OwnedFungibleResource: Comparable {
	static func < (
		lhs: OnLedgerEntity.OwnedFungibleResource,
		rhs: OnLedgerEntity.OwnedFungibleResource
	) -> Bool {
		if let lhsFiatWorth = lhs.amount.exactAmount?.fiatWorth, let rhsFiathWorth = rhs.amount.exactAmount?.fiatWorth {
			return lhsFiatWorth > rhsFiathWorth // Sort descending by fiat worth
		}

		if lhs.amount.exactAmount?.fiatWorth != nil || rhs.amount.exactAmount?.fiatWorth != nil {
			return lhs.amount.exactAmount?.fiatWorth != nil
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
}

// MARK: - OnLedgerEntity.OwnedNonFungibleResource + Comparable
extension OnLedgerEntity.OwnedNonFungibleResource: Comparable {
	static func < (
		lhs: Self,
		rhs: Self
	) -> Bool {
		switch (lhs.metadata.name, rhs.metadata.name) {
		case let (.some(lhsName), .some(rhsName)):
			lhsName < rhsName
		case (nil, .some):
			false
		case (.some, nil):
			true
		default:
			lhs.resourceAddress.address < rhs.resourceAddress.address
		}
	}
}

// MARK: - OnLedgerEntity.OnLedgerAccount.PoolUnit + Comparable
extension OnLedgerEntity.OnLedgerAccount.PoolUnit: Comparable {
	static func < (
		lhs: Self,
		rhs: Self
	) -> Bool {
		lhs.resource < rhs.resource
	}
}

extension Optional {
	func asArray<T>(_ keyPath: KeyPath<Wrapped, T>) -> [T] {
		if let wrapped = self {
			return [wrapped[keyPath: keyPath]]
		}
		return []
	}

	mutating func mutate(_ mutate: (inout Wrapped) -> Void) {
		guard case var .some(wrapped) = self else {
			return
		}
		mutate(&wrapped)
		self = .some(wrapped)
	}
}
