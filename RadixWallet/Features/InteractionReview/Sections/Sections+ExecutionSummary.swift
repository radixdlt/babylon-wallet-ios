extension InteractionReview.Sections {
	// Either the resource from ledger or metadata extracted from the TX manifest
	typealias ResourceInfo = Either<OnLedgerEntity.Resource, OnLedgerEntity.Metadata>
	typealias ResourcesInfo = [ResourceAddress: ResourceInfo]
	typealias ResourceAssociatedDapps = [ResourceAddress: OnLedgerEntity.Metadata]

	func sections(for summary: ExecutionSummary, networkID: NetworkID) async throws -> Common.SectionsData? {
		let allWithdrawAddresses = summary.withdrawals.values.flatMap { $0 }.map(\.resourceAddress)
		let allDepositAddresses = summary.deposits.values.flatMap { $0 }.map(\.resourceAddress)

		// Pre-populate with all resource addresses from withdraw and deposit.
		let allAddresses: IdentifiedArrayOf<ResourceAddress> = Array((allWithdrawAddresses + allDepositAddresses).uniqued()).asIdentified()

		func resourcesInfo(_ resourceAddresses: [ResourceAddress]) async throws -> ResourcesInfo {
			var newlyCreatedMetadata = try Dictionary(
				keysWithValues: resourceAddresses.compactMap { resourceAddress in
					summary.newEntities.metadata[resourceAddress].map {
						(
							resourceAddress,
							ResourceInfo.right(OnLedgerEntity.Metadata(newlyCreated: $0))
						)
					}
				}
			)

			let existingResources = resourceAddresses.filter {
				newlyCreatedMetadata[$0] == nil
			}

			let existingResourceDetails = try await onLedgerEntitiesClient.getResources(existingResources)
				.reduce(into: ResourcesInfo()) { partialResult, next in
					partialResult[next.resourceAddress] = .left(next)
				}

			newlyCreatedMetadata.append(contentsOf: existingResourceDetails)

			return newlyCreatedMetadata
		}

		switch summary.detailedManifestClass {
		case nil:
			return nil

		case .general, .transfer:
			if summary.detailedManifestClass == .general {
				guard !summary.deposits.isEmpty || !summary.withdrawals.isEmpty else { return nil }
			}

			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.withdrawals,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			let dappAddresses = summary.encounteredAddresses.compactMap {
				switch $0 {
				case let .component(componentAddress):
					componentAddress.isGlobal ? componentAddress.asGeneral : nil
				case let .locker(lockerAddress):
					lockerAddress.asGeneral
				}
			}

			let dAppsUsed = try await extractDapps(
				addresses: dappAddresses,
				unknownTitle: L10n.TransactionReview.unknownComponents
			)

			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			let proofs = try await exctractProofs(summary.presentedProofs)

			return Common.SectionsData(
				withdrawals: withdrawals,
				dAppsUsed: dAppsUsed,
				deposits: deposits,
				proofs: proofs
			)

		case let .poolContribution(poolAddresses, poolContributions):
			// All resources that are part of the pool
			let resourceAddresses = poolContributions.flatMap { Array($0.contributedResources.keys) }

			let allAddresses = allAddresses + resourceAddresses.asIdentified()
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let dApps = await extractDappEntities(poolAddresses.map(\.asGeneral))

			let perPoolUnitDapps = try perPoolUnitDapps(dApps, poolInteractions: poolContributions)

			// Extract Contributing to Pools section
			let pools: InteractionReviewPools.State? = try await extractDapps(dApps, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Withdrawals section
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.withdrawals,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				networkID: networkID
			)

			// Extract Deposits section, passing in poolcontributions so that pool units can be updated
			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				poolContributions: poolContributions.aggregated,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				networkID: networkID
			)

			return Common.SectionsData(
				withdrawals: withdrawals,
				deposits: deposits,
				contributingToPools: pools
			)

		case let .poolRedemption(poolAddresses, poolRedemptions):
			// All resources that are part of the pool
			let resourceAddresses = poolRedemptions.flatMap {
				Array($0.redeemedResources.keys)
			}

			let allAddresses = allAddresses + resourceAddresses.asIdentified()
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let dApps = await extractDappEntities(poolAddresses.map(\.asGeneral))

			let perPoolUnitDapps = try perPoolUnitDapps(dApps, poolInteractions: poolRedemptions)

			// Extract Contributing to Pools section
			let pools: InteractionReviewPools.State? = try await extractDapps(dApps, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Withdrawals section, passing in poolRedemptions so that withdrawn pool units can be updated
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.withdrawals,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				poolRedemptions: poolRedemptions.aggregated,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				networkID: networkID
			)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				networkID: networkID
			)

			return Common.SectionsData(
				withdrawals: withdrawals,
				deposits: deposits,
				redeemingFromPools: pools
			)

		case let .validatorStake(validatorAddresses: validatorAddresses, validatorStakes: validatorStakes):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.withdrawals,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			// Extract validators
			let stakingToValidators = try await extractValidators(for: validatorAddresses)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				validatorStakes: validatorStakes.aggregated,
				entities: resourcesInfo,
				networkID: networkID
			)

			return Common.SectionsData(
				withdrawals: withdrawals,
				deposits: deposits,
				stakingToValidators: stakingToValidators
			)

		case let .validatorUnstake(validatorAddresses, claimsNonFungibleData):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.withdrawals,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			// Extract validators
			let unstakingFromValidators = try await extractValidators(for: validatorAddresses)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				unstakeData: claimsNonFungibleData,
				entities: resourcesInfo,
				networkID: networkID
			)

			return Common.SectionsData(
				withdrawals: withdrawals,
				deposits: deposits,
				unstakingFromValidators: unstakingFromValidators
			)

		case let .validatorClaim(validatorAddresses, _):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try? await extractWithdrawals(
				accountWithdraws: summary.withdrawals.aggregated,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			let claimingFromValidators = try await extractValidators(
				for: validatorAddresses
			)

			let deposits = try? await extractDeposits(
				accountDeposits: summary.deposits.aggregated,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			return Common.SectionsData(
				withdrawals: withdrawals,
				deposits: deposits,
				claimingFromValidators: claimingFromValidators
			)

		case let .accountDepositSettingsUpdate(
			resourcePreferencesUpdates,
			depositModeUpdates,
			authorizedDepositorsAdded,
			authorizedDepositorsRemoved
		):

			let allAccountAddress = Set(authorizedDepositorsAdded.keys)
				.union(authorizedDepositorsRemoved.keys)
				.union(depositModeUpdates.keys)
				.union(resourcePreferencesUpdates.keys)

			let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork() // TODO: Use general one

			let validAccounts = allAccountAddress.compactMap { address in
				userAccounts.first { $0.address == address }
			}

			let accountDepositSetting = extractAccountDepositSetting(
				for: validAccounts,
				defaultDepositRuleChanges: depositModeUpdates
			)
			let accountDepositExceptions = try await extractAccountDepositExceptions(
				for: validAccounts,
				resourcePreferenceChanges: resourcePreferencesUpdates,
				authorizedDepositorsAdded: authorizedDepositorsAdded,
				authorizedDepositorsRemoved: authorizedDepositorsRemoved
			)

			return Common.SectionsData(
				accountDepositSetting: accountDepositSetting,
				accountDepositExceptions: accountDepositExceptions
			)
		}
	}

	private func extractUserAccounts(_ allAddress: [AccountAddress]) async throws -> [Common.ReviewAccount] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

		return allAddress
			.map { (address: AccountAddress) in
				let userAccount = userAccounts.first { userAccount in
					userAccount.address.address == address.address
				}
				if let userAccount {
					return .user(userAccount)
				} else {
					return .external(address, approved: false)
				}
			}
	}

	private func extractDapps(
		addresses: [Address],
		unknownTitle: (Int) -> String
	) async throws -> InteractionReviewDapps<ComponentAddress>.State? {
		let dApps = await extractDappEntities(addresses)
		return try await extractDapps(dApps, unknownTitle: unknownTitle)
	}

	private func extractDapps<A: AddressProtocol>(
		_ dAppEntities: [(address: Address, entity: InteractionReview.DappEntity?)],
		unknownTitle: (Int) -> String
	) async throws -> InteractionReviewDapps<A>.State? {
		let knownDapps = dAppEntities.compactMap(\.entity).asIdentified()
		let unknownDapps = try dAppEntities.filter { $0.entity == nil }
			.map { try $0.address.asSpecific(type: A.self) }.asIdentified()

		guard knownDapps.count + unknownDapps.count > 0 else { return nil }

		return .init(knownDapps: knownDapps, unknownDapps: unknownDapps, unknownTitle: unknownTitle)
	}

	private func extractDappEntities(_ addresses: [Address]) async -> [(address: Address, entity: InteractionReview.DappEntity?)] {
		await addresses.asyncMap {
			await (address: $0, entity: try? extractDappEntity($0.asGeneral))
		}
	}

	private func extractDappEntity(_ entity: Address) async throws -> InteractionReview.DappEntity {
		let dAppDefinitionAddress = try await onLedgerEntitiesClient.getDappDefinitionAddress(entity)
		let metadata = try await onLedgerEntitiesClient.getDappMetadata(dAppDefinitionAddress, validatingDappEntity: entity)
		return .init(id: dAppDefinitionAddress, metadata: metadata)
	}

	private func exctractProofs(_ accountProofs: [ResourceSpecifier]) async throws -> Common.Proofs.State? {
		let proofs = try await accountProofs
			.uniqued()
			.asyncMap(extractResourceBalanceInfo)
			.flatMap { $0 }
			.asyncMap(extractProofInfo)

		guard !proofs.isEmpty else { return nil }

		return Common.Proofs.State(kind: .transaction, proofs: proofs.asIdentified())
	}

	private func extractResourceBalanceInfo(specifier: ResourceSpecifier) async throws -> [(ResourceAddress, ResourceBalance.Details)] {
		switch specifier {
		case let .fungible(resourceAddress, amount):
			return [(
				resourceAddress,
				.fungible(
					.init(
						isXRD: resourceAddress.isXRD,
						amount: .init(nominalAmount: amount)
					)
				)
			)]
		case let .nonFungible(resourceAddress, ids):
			let globalIds = ids.map { NonFungibleGlobalId(resourceAddress: resourceAddress, nonFungibleLocalId: $0) }
			let tokens = try await onLedgerEntitiesClient.getNonFungibleTokenData(
				.init(resource: resourceAddress, nonFungibleIds: globalIds)
			)
			return tokens.map { (resourceAddress, .nonFungible($0)) }
		}
	}

	private func extractProofInfo(resourceAddress: ResourceAddress, details: ResourceBalance.Details) async throws -> Common.ProofEntity {
		try await Common.ProofEntity(
			resourceBalance: ResourceBalance(
				resource: onLedgerEntitiesClient.getResource(resourceAddress, metadataKeys: .dappMetadataKeys),
				details: details
			)
		)
	}

	private func extractWithdrawals(
		accountWithdraws: [AccountAddress: [ResourceIndicator]],
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolRedemptions: [TrackedPoolRedemption] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID
	) async throws -> Common.Accounts.State? {
		var withdrawals: [Common.ReviewAccount: IdentifiedArrayOf<Common.Transfer>] = [:]
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(Array(accountWithdraws.keys))

		for (accountAddress, resources) in accountWithdraws {
			let account = try userAccounts.account(for: accountAddress)
			let transfers = try await resources.asyncFlatMap {
				try await transferInfo(
					resourceQuantifier: $0,
					newlyCreatedNonFungibles: newlyCreatedNonFungibles,
					poolInteractions: poolRedemptions,
					entities: entities,
					resourceAssociatedDapps: resourceAssociatedDapps,
					networkID: networkID,
					type: .exact
				)
			}
			.map(\.asIdentified)

			withdrawals[account, default: []].append(contentsOf: transfers)
		}

		guard !withdrawals.isEmpty else { return nil }

		let withdrawalAccounts = withdrawals.map {
			Common.Account.State(account: $0.key, transfers: $0.value, isDeposit: false)
		}
		.asIdentified()

		return .init(accounts: withdrawalAccounts, enableCustomizeGuarantees: false)
	}

	private func extractDeposits(
		accountDeposits: [AccountAddress: [ResourceIndicator]],
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolContributions: [TrackedPoolContribution] = [],
		validatorStakes: [TrackedValidatorStake] = [],
		unstakeData: [NonFungibleGlobalId: UnstakeData] = [:],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID
	) async throws -> Common.Accounts.State? {
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(Array(accountDeposits.keys))
		let defaultDepositGuarantee = await appPreferencesClient.getPreferences().transaction.defaultDepositGuarantee

		var deposits: [Common.ReviewAccount: IdentifiedArrayOf<Common.Transfer>] = [:]

		for (accountAddress, accountDeposits) in accountDeposits {
			let account = try userAccounts.account(for: accountAddress)
			let transfers = try await accountDeposits.asyncFlatMap {
				let aux = try await transferInfo(
					resourceQuantifier: $0,
					newlyCreatedNonFungibles: newlyCreatedNonFungibles,
					poolInteractions: poolContributions,
					validatorStakes: validatorStakes,
					unstakeData: unstakeData,
					entities: entities,
					resourceAssociatedDapps: resourceAssociatedDapps,
					networkID: networkID,
					type: $0.transferType,
					defaultDepositGuarantee: defaultDepositGuarantee
				)
				return aux
			}
			.map(\.asIdentified)

			deposits[account, default: []].append(contentsOf: transfers)
		}

		let depositAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { Common.Account.State(account: $0.key, transfers: $0.value, isDeposit: true) }
			.asIdentified()

		guard !depositAccounts.isEmpty else { return nil }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty
		return .init(accounts: depositAccounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	func extractValidators(for addresses: [ValidatorAddress]) async throws -> Common.ValidatorsState? {
		guard !addresses.isEmpty else { return nil }

		let validators = try await onLedgerEntitiesClient.getEntities(
			addresses: addresses.map(\.asGeneral),
			metadataKeys: .resourceMetadataKeys
		)

		.compactMap { entity -> Common.ValidatorState? in
			guard let validator = entity.validator else { return nil }
			return .init(
				address: validator.address,
				name: validator.metadata.name,
				thumbnail: validator.metadata.iconURL
			)
		}

		guard validators.count == addresses.count else {
			struct FailedToExtractValidatorInformation: Error {}
			throw FailedToExtractValidatorInformation()
		}

		return .init(validators: validators)
	}

	func extractAccountDepositSetting(
		for validAccounts: [Account],
		defaultDepositRuleChanges: [AccountAddress: AccountDefaultDepositRule]
	) -> TransactionReview.DepositSettingState? {
		let depositSettingChanges: [TransactionReview.DepositSettingChange] = validAccounts.compactMap { account in
			guard let depositRuleChange = defaultDepositRuleChanges[account.address] else { return nil }
			return .init(account: account, ruleChange: depositRuleChange)
		}

		guard !depositSettingChanges.isEmpty else { return nil }

		return .init(changes: IdentifiedArray(uncheckedUniqueElements: depositSettingChanges))
	}

	func extractAccountDepositExceptions(
		for validAccounts: [Account],
		resourcePreferenceChanges: [AccountAddress: [ResourceAddress: ResourcePreferenceUpdate]],
		authorizedDepositorsAdded: [AccountAddress: [ResourceOrNonFungible]],
		authorizedDepositorsRemoved: [AccountAddress: [ResourceOrNonFungible]]
	) async throws -> TransactionReview.DepositExceptionsState? {
		let exceptionChanges: [TransactionReview.DepositExceptionsChange] = try await validAccounts.asyncCompactMap { account in
			let resourcePreferenceChanges = try await resourcePreferenceChanges[account.address]?
				.asyncMap { resourcePreference in
					try await TransactionReview.DepositExceptionsChange.ResourcePreferenceChange(
						resource: onLedgerEntitiesClient.getResource(resourcePreference.key),
						change: resourcePreference.value
					)
				} ?? []

			let authorizedDepositorChanges = try await {
				var changes: [TransactionReview.DepositExceptionsChange.AllowedDepositorChange] = []
				if let authorizedDepositorsAdded = authorizedDepositorsAdded[account.address] {
					let added = try await authorizedDepositorsAdded.asyncMap { resourceOrNonFungible in
						let resourceAddress = resourceOrNonFungible.resourceAddress
						return try await TransactionReview.DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .added
						)
					}
					changes.append(contentsOf: added)
				}
				if let authorizedDepositorsRemoved = authorizedDepositorsRemoved[account.address] {
					let removed = try await authorizedDepositorsRemoved.asyncMap { resourceOrNonFungible in
						let resourceAddress = resourceOrNonFungible.resourceAddress
						return try await TransactionReview.DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .removed
						)
					}
					changes.append(contentsOf: removed)
				}

				return changes
			}()

			guard !resourcePreferenceChanges.isEmpty || !authorizedDepositorChanges.isEmpty else { return nil }

			return TransactionReview.DepositExceptionsChange(
				account: account,
				resourcePreferenceChanges: IdentifiedArray(uncheckedUniqueElements: resourcePreferenceChanges),
				allowedDepositorChanges: IdentifiedArray(uncheckedUniqueElements: authorizedDepositorChanges)
			)
		}

		guard !exceptionChanges.isEmpty else { return nil }

		return .init(changes: IdentifiedArray(uncheckedUniqueElements: exceptionChanges))
	}

	private func perPoolUnitDapps(
		_ dappEntities: [(address: Address, entity: InteractionReview.DappEntity?)],
		poolInteractions: [some TrackedPoolInteraction]
	) throws -> ResourceAssociatedDapps {
		try Dictionary(keysWithValues: dappEntities.compactMap { data -> (ResourceAddress, OnLedgerEntity.Metadata)? in
			let poolUnitResource: ResourceAddress? = poolInteractions
				.first(where: { $0.poolAddress.asGeneral == data.address })?
				.poolUnitsResourceAddress

			guard let poolUnitResource,
			      let dAppMetadata = data.entity?.metadata
			else {
				return nil
			}

			return (poolUnitResource, dAppMetadata)
		})
	}
}

extension InteractionReview.Sections {
	struct ResourceEntityNotFound: Error {
		let address: String
	}

	struct FailedToGetDataForAllNFTs: Error {}
	struct FailedToGetPoolUnitDetails: Error {}
	struct StakeUnitAddressMismatch: Error {}
	struct MissingTrackedValidatorStake: Error {}
	struct MissingPositiveTotalSupply: Error {}
	struct InvalidStakeClaimToken: Error {}
	struct MissingStakeClaimTokenData: Error {}

	func transferInfo(
		resourceQuantifier: ResourceIndicator,
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolInteractions: [some TrackedPoolInteraction] = [],
		validatorStakes: [TrackedValidatorStake] = [],
		unstakeData: [NonFungibleGlobalId: UnstakeData] = [:],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		type: TransactionReview.TransferType,
		defaultDepositGuarantee: Decimal192 = 1
	) async throws -> [ResourceBalance] {
		let resourceAddress: ResourceAddress = resourceQuantifier.resourceAddress

		guard let resourceInfo = entities[resourceAddress] else {
			throw ResourceEntityNotFound(address: resourceAddress.address)
		}

		switch resourceQuantifier {
		case let .fungible(_, source):
			switch resourceInfo {
			case let .left(resource):
				return try await [onLedgerEntitiesClient.fungibleResourceBalance(
					resource,
					resourceQuantifier: source,
					poolContributions: poolInteractions,
					validatorStakes: validatorStakes,
					entities: entities,
					resourceAssociatedDapps: resourceAssociatedDapps,
					networkID: networkID,
					defaultDepositGuarantee: defaultDepositGuarantee
				)]
			case let .right(newEntityMetadata):
				// A newly created fungible resource

				let resource: OnLedgerEntity.Resource = .init(
					resourceAddress: resourceAddress,
					metadata: newEntityMetadata
				)

				let details: ResourceBalance.Fungible = .init(
					isXRD: false,
					amount: .init(nominalAmount: source.amount),
					guarantee: nil
				)

				return [.init(resource: resource, details: .fungible(details), isHidden: false)]
			}

		case let .nonFungible(_, indicator):
			return try await onLedgerEntitiesClient.nonFungibleResourceBalances(
				resourceInfo,
				resourceAddress: resourceAddress,
				resourceQuantifier: indicator,
				unstakeData: unstakeData,
				newlyCreatedNonFungibles: newlyCreatedNonFungibles
			)
		}
	}
}

extension [AccountAddress: [ResourceIndicator]] {
	/// Aggregate the transfer amounts for the same resource for the same account.
	///
	/// The RET analysis might return multiple withdrawls/deposits for the same resource,
	/// instead of showing separate entries for each withdral/deposit, we aggregate
	/// the fungible amounts or the non fungible ids.
	///
	/// Important note: This aggregates only the guranteed amounts,
	/// predicted amounts cannot be aggregated since each amount will have a specific instruction index attached.
	///
	/// This function is only used curently for stake claim transactions, when the Dapp might sent a manifest
	/// which is interpreted by RET as having multiple distinct withdrawls/deposits for the same resource.
	///
	/// This should eventually be moved to RET, so it should return the aggregated amounts
	var aggregated: Self {
		var aggregatedResult: Self = [:]

		for (key, value) in self {
			var result: [ResourceIndicator] = []
			for indicator in value {
				if let i = result.firstIndex(where: {
					$0.resourceAddress == indicator.resourceAddress &&
						$0.isGuaranteedAmount &&
						indicator.isGuaranteedAmount
				}) {
					result[i].add(indicator)
				} else {
					result.append(indicator)
				}
			}

			aggregatedResult[key] = result
		}
		return aggregatedResult
	}
}

extension ResourceIndicator {
	var isGuaranteedAmount: Bool {
		switch self {
		case .fungible(_, .guaranteed), .nonFungible(_, .byIds):
			return true
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return false // Cannot sum up the predicted amounts, as each predicted amount has a specific instruction index
		}
	}

	mutating func add(_ other: Self) {
		guard other.resourceAddress == resourceAddress else {
			assertionFailure("The indicators should have the same resource address")
			return
		}
		switch (self, other) {
		case let (.fungible(_, fungibleIndicator), .fungible(_, otherFungibleIndicator)):
			self = .fungible(
				resourceAddress: resourceAddress,
				indicator: fungibleIndicator.adding(otherFungibleIndicator)
			)
		case let (.nonFungible(_, nonFungibleIndicator), .nonFungible(_, otherNonFungibleIndicator)):
			self = .nonFungible(
				resourceAddress: resourceAddress,
				indicator: nonFungibleIndicator.adding(otherNonFungibleIndicator)
			)
		default:
			assertionFailure("Trying to add together two different kinds of resources")
			return
		}
	}
}

extension FungibleResourceIndicator {
	func adding(_ other: Self) -> Self {
		switch (self, other) {
		case let (.guaranteed(amount), .guaranteed(otherAmount)):
			return .guaranteed(decimal: amount + otherAmount)
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return self
		}
	}
}

extension NonFungibleResourceIndicator {
	func adding(_ other: Self) -> Self {
		switch (self, other) {
		case let (.byIds(ids), .byIds(otherIds)):
			return .byIds(ids: ids + otherIds)
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return self
		}
	}
}
