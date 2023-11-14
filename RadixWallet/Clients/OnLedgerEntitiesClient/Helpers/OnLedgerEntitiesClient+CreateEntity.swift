
extension OnLedgerEntitiesClient {
	@Sendable
	static func createEntity(
		from item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState,
		forceRefresh: Bool = false
	) async throws -> OnLedgerEntity? {
		let address = try Address(validatingAddress: item.address)
		let addressKind = address.decodedKind
		switch addressKind {
		case _ where AccountEntityType.addressSpace.contains(addressKind):
			return try await .account(createAccount(
				item,
				ledgerState: ledgerState,
				forceRefresh: forceRefresh
			))
		case _ where ResourceEntityType.addressSpace.contains(addressKind):
			return try createResource(item, ledgerState: ledgerState).map(OnLedgerEntity.resource)
		case _ where ResourcePoolEntityType.addressSpace.contains(addressKind):
			guard let resourcePool = try await createResourcePool(
				item,
				ledgerState: ledgerState
			) else {
				return nil
			}

			return .resourcePool(resourcePool)
		case _ where ValidatorEntityType.addressSpace.contains(addressKind):
			guard let validator = try await createValidator(
				item,
				ledgerState: ledgerState
			) else {
				return nil
			}
			return .validator(validator)
		default:
			return try .genericComponent(createGenericComponent(item, ledgerState: ledgerState))
		}
	}

	@Sendable
	static func createAccount(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState,
		forceRefresh: Bool = false
	) async throws -> OnLedgerEntity.Account {
		let accountAddress = try AccountAddress(validatingAddress: item.address)
		let fungibleResources = try extractOwnedFungibleResources(item, ledgerState: ledgerState)
		let nonFungibleResources = try extractOwnedNonFungibleResources(item, ledgerState: ledgerState)

		let poolUnitResources = try await createPoolUnitResources(
			accountAddress.address,
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
			metadata: .init(item.explicitMetadata),
			fungibleResources: filteredFungibleResources.sorted(),
			nonFungibleResources: filteredNonFungibleResources.sorted(),
			poolUnitResources: poolUnitResources
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
			metadata: .init(item.explicitMetadata)
		)
	}

	@Sendable
	static func createResource(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) throws -> OnLedgerEntity.Resource? {
		switch item.details {
		case let .fungibleResource(fungibleDetails):
			try .init(
				resourceAddress: .init(validatingAddress: item.address),
				atLedgerState: ledgerState,
				divisibility: fungibleDetails.divisibility,
				behaviors: item.details?.fungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: fungibleDetails.totalSupply),
				metadata: .init(item.explicitMetadata)
			)
		case let .nonFungibleResource(nonFungibleDetails):
			try .init(
				resourceAddress: .init(validatingAddress: item.address),
				atLedgerState: ledgerState,
				divisibility: nil,
				behaviors: item.details?.nonFungible?.roleAssignments.extractBehaviors() ?? [],
				totalSupply: try? RETDecimal(value: nonFungibleDetails.totalSupply),
				metadata: .init(item.explicitMetadata)
			)
		default:
			nil
		}
	}

	@Sendable
	static func createResourcePool(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
		ledgerState: AtLedgerState
	) async throws -> OnLedgerEntity.ResourcePool? {
		guard let state: GatewayAPI.ResourcePoolState = try? item.details?.component?.decodeState() else {
			assertionFailure("Invalid resource pool state")
			return nil
		}

		return try await .init(
			address: .init(validatingAddress: item.address),
			poolUnitResourceAddress: .init(validatingAddress: state.poolUnitResourceAddress),
			resources: extractOwnedFungibleResources(item, ledgerState: ledgerState).sorted(),
			metadata: .init(item.explicitMetadata)
		)
	}

	@Sendable
	static func createValidator(
		_ item: GatewayAPI.StateEntityDetailsResponseItem,
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
			assertionFailure("Validator XRD Resource didn't contain the \(state.stakeXRDVaultAddress) vault ")
			return nil
		}

		return try .init(
			address: .init(validatingAddress: item.address),
			stakeUnitResourceAddress: .init(validatingAddress: state.stakeUnitResourceAddress),
			xrdVaultBalance: .init(value: xrdStakeVaultBalance),
			stakeClaimFungibleResourceAddress: .init(validatingAddress: state.unstakeClaimTokenResourceAddress),
			metadata: .init(item.explicitMetadata)
		)
	}

	@Sendable
	static func createPoolUnitResources(
		_ accountAddress: String,
		rawFungibleResources: [OnLedgerEntity.OwnedFungibleResource],
		rawNonFungibleResources: [OnLedgerEntity.OwnedNonFungibleResource],
		ledgerState: AtLedgerState,
		forceRefresh: Bool = false
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
			stakeUnitCandidates.compactMap(\.metadata.validator?.asGeneral)
				+ stakeClaimNFTCandidates.compactMap(\.metadata.validator?.asGeneral)
				+ poolUnitCandidates.compactMap(\.metadata.poolUnit?.asGeneral)
		)

		guard !stakeAndPoolAddresses.isEmpty else {
			return .init(radixNetworkStakes: [], poolUnits: [])
		}

		let entities = try await getEntities(
			for: Array(stakeAndPoolAddresses),
			.resourceMetadataKeys,
			ledgerState: ledgerState,
			forceRefresh: forceRefresh
		)
		let validators = entities.compactMap(\.validator)
		let resourcesPools = entities.compactMap(\.resourcePool)

		let stakeUnits = validators.compactMap { validator -> OnLedgerEntity.Account.RadixNetworkStake? in
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

		let poolUnits = resourcesPools.compactMap { pool -> OnLedgerEntity.Account.PoolUnit? in
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

			return OnLedgerEntity.Account.PoolUnit(resource: poolUnitResource, resourcePoolAddress: pool.address)
		}

		return .init(radixNetworkStakes: stakeUnits, poolUnits: poolUnits)
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

			let amount = try RETDecimal(value: vault.amount)
			return try .init(
				resourceAddress: .init(validatingAddress: vaultAggregated.resourceAddress),
				atLedgerState: ledgerState,
				amount: amount,
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
	/// This loads all of the related pool unit details required by the Pool units screen.
	/// We don't do any pagination there(yet), since the number of owned pools will not be big, this can be revised in the future.
	@Sendable
	public func getOwnedPoolUnitsDetails(
		_ account: OnLedgerEntity.Account,
		refresh: Bool = false
	) async throws -> [OwnedResourcePoolDetails] {
		let ownedPoolUnits = account.poolUnitResources.poolUnits
		let pools = try await getEntities(
			ownedPoolUnits.map(\.resourcePoolAddress.asGeneral),
			[],
			account.atLedgerState,
			refresh
		).compactMap(\.resourcePool)

		var allResourceAddresses: [ResourceAddress] = []
		for pool in pools {
			allResourceAddresses.append(pool.poolUnitResourceAddress)
			allResourceAddresses += pool.resources.nonXrdResources.map(\.resourceAddress)
			if let xrdResource = pool.resources.xrdResource {
				allResourceAddresses.append(xrdResource.resourceAddress)
			}
		}

		let allResources = try await getResources(allResourceAddresses, atLedgerState: account.atLedgerState, forceRefresh: refresh)

		return ownedPoolUnits.compactMap { ownedPoolUnit -> OwnedResourcePoolDetails? in
			guard let pool = pools.first(where: { $0.address == ownedPoolUnit.resourcePoolAddress }) else {
				assertionFailure("Did not load pool details")
				return nil
			}
			guard let poolUnitResource = allResources.first(where: { $0.resourceAddress == pool.poolUnitResourceAddress }) else {
				assertionFailure("Did not load poolUnitResource details")
				return nil
			}

			var nonXrdResourceDetails: [ResourceWithVaultAmount] = []

			for resource in pool.resources.nonXrdResources {
				guard let resourceDetails = allResources.first(where: { $0.resourceAddress == resource.resourceAddress }) else {
					assertionFailure("Did not load resource details")
					return nil
				}
				nonXrdResourceDetails.append(.init(resource: resourceDetails, amount: resource.amount))
			}

			let xrdResourceDetails: ResourceWithVaultAmount?
			if let xrdResource = pool.resources.xrdResource {
				guard let details = allResources.first(where: { $0.resourceAddress == xrdResource.resourceAddress }) else {
					assertionFailure("Did not load xrd resource details")
					return nil
				}
				xrdResourceDetails = .init(resource: details, amount: xrdResource.amount)
			} else {
				xrdResourceDetails = nil
			}

			return .init(
				address: pool.address,
				poolUnitResource: .init(resource: poolUnitResource, amount: ownedPoolUnit.resource.amount),
				xrdResource: xrdResourceDetails,
				nonXrdResources: nonXrdResourceDetails
			)
		}
	}

	/// This loads all of the related stake unit details required by the Pool Units screen.
	/// We don't do any pagination there(yet), since the number of owned stakes will not be big, this can be revised in the future.
	public func getOwnedStakesDetails(
		account: OnLedgerEntity.Account,
		refresh: Bool = false
	) async throws -> [OwnedStakeDetails] {
		let ownedStakes = account.poolUnitResources.radixNetworkStakes
		let validators = try await getEntities(
			ownedStakes.map(\.validatorAddress.asGeneral),
			.resourceMetadataKeys,
			account.atLedgerState,
			refresh
		).compactMap(\.validator)

		let resourceAddresses = ownedStakes.flatMap {
			$0.stakeUnitResource.asArray(\.resourceAddress) + $0.stakeClaimResource.asArray(\.resourceAddress)
		}

		let resourceDetails = try await getResources(resourceAddresses, atLedgerState: account.atLedgerState, forceRefresh: refresh)

		@Dependency(\.gatewayAPIClient) var gatewayAPIClient
		let currentEpoch = try await gatewayAPIClient.getEpoch()

		return try await ownedStakes.asyncCompactMap { stake -> OwnedStakeDetails? in
			guard let validatorDetails = validators.first(where: { $0.address == stake.validatorAddress }) else {
				assertionFailure("Did not load validator details")
				return nil
			}

			let stakeUnitResource: ResourceWithVaultAmount? = {
				if let stakeUnitResource = stake.stakeUnitResource, stakeUnitResource.amount > 0 {
					guard let stakeUnitDetails = resourceDetails.first(where: { $0.resourceAddress == stakeUnitResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						return nil
					}
					return .init(resource: stakeUnitDetails, amount: stakeUnitResource.amount)
				}

				return nil
			}()

			let stakeClaimTokens: NonFunbileResourceWithTokens? = try await {
				if let stakeClaimResource = stake.stakeClaimResource, stakeClaimResource.nonFungibleIdsCount > 0 {
					guard let stakeClaimResourceDetails = resourceDetails.first(where: { $0.resourceAddress == stakeClaimResource.resourceAddress }) else {
						assertionFailure("Did not load stake unit details")
						return nil
					}
					let tokenData = try await getAccountOwnedNonFungibleTokenData(.init(
						accountAddress: account.address,
						resource: stakeClaimResource,
						mode: .loadAll
					)).tokens
					return .init(resource: stakeClaimResourceDetails, tokens: tokenData)
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

extension OnLedgerEntity.Account.PoolUnitResources {
	var nonEmptyVaults: OnLedgerEntity.Account.PoolUnitResources {
		let stakes = radixNetworkStakes.compactMap { stake in
			let stakeUnitResource: OnLedgerEntity.OwnedFungibleResource? = {
				guard let stakeUnitResource = stake.stakeUnitResource, stakeUnitResource.amount > 0 else {
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
				return OnLedgerEntity.Account.RadixNetworkStake(
					validatorAddress: stake.validatorAddress,
					stakeUnitResource: stakeUnitResource,
					stakeClaimResource: stakeClaimNFT
				)
			}
			return nil
		}

		return .init(radixNetworkStakes: stakes, poolUnits: poolUnits)
	}
}

extension [OnLedgerEntity.OwnedNonFungibleResource] {
	public var nonEmptyVaults: [OnLedgerEntity.OwnedNonFungibleResource] {
		filter { $0.nonFungibleIdsCount > 0 }
	}
}

extension OnLedgerEntity.OwnedFungibleResources {
	public var nonEmptyVaults: OnLedgerEntity.OwnedFungibleResources {
		.init(
			xrdResource: xrdResource.flatMap { $0.amount > 0 ? $0 : nil },
			nonXrdResources: nonXrdResources.filter { $0.amount > 0 }
		)
	}
}

extension OnLedgerEntity.Account {
	public var nonEmptyVaults: OnLedgerEntity.Account {
		.init(
			address: address,
			atLedgerState: atLedgerState,
			metadata: metadata,
			fungibleResources: fungibleResources.nonEmptyVaults,
			nonFungibleResources: nonFungibleResources.nonEmptyVaults,
			poolUnitResources: poolUnitResources.nonEmptyVaults
		)
	}
}

extension OnLedgerEntitiesClient {
	public struct OwnedStakeDetails: Hashable, Sendable {
		public let validator: OnLedgerEntity.Validator
		public let stakeUnitResource: ResourceWithVaultAmount?
		public let stakeClaimTokens: NonFunbileResourceWithTokens?
		public let currentEpoch: Epoch
	}

	public struct OwnedResourcePoolDetails: Hashable, Sendable {
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

extension [OnLedgerEntity.OwnedFungibleResource] {
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

		let sortedNonXrdResources = nonXrdResources.sorted(by: <)

		return .init(xrdResource: xrdResource, nonXrdResources: sortedNonXrdResources)
	}
}

// MARK: - OnLedgerEntity.OwnedFungibleResource + Comparable
extension OnLedgerEntity.OwnedFungibleResource: Comparable {
	public static func < (
		lhs: OnLedgerEntity.OwnedFungibleResource,
		rhs: OnLedgerEntity.OwnedFungibleResource
	) -> Bool {
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
}

// MARK: - OnLedgerEntity.OwnedNonFungibleResource + Comparable
extension OnLedgerEntity.OwnedNonFungibleResource: Comparable {
	public static func < (
		lhs: OnLedgerEntity.OwnedNonFungibleResource,
		rhs: OnLedgerEntity.OwnedNonFungibleResource
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

extension Optional {
	func asArray<T>(_ keyPath: KeyPath<Wrapped, T>) -> [T] {
		if let wrapped = self {
			return [wrapped[keyPath: keyPath]]
		}
		return []
	}
}
