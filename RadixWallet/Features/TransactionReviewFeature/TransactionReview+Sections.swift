import Foundation

extension TransactionReview {
	// Either the resource from ledger or metadata extracted from the TX manifest
	public typealias ResourceInfo = Either<OnLedgerEntity.Resource, OnLedgerEntity.Metadata>
	public typealias ResourcesInfo = [ResourceAddress: ResourceInfo]
	public typealias ResourceAssociatedDapps = [ResourceAddress: OnLedgerEntity.Metadata]

	public struct Sections: Sendable, Hashable {
		var withdrawals: TransactionReviewAccounts.State? = nil
		var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		var deposits: TransactionReviewAccounts.State? = nil

		var contributingToPools: TransactionReviewPools.State? = nil
		var redeemingFromPools: TransactionReviewPools.State? = nil

		var stakingToValidators: ValidatorsState? = nil
		var unstakingFromValidators: ValidatorsState? = nil
		var claimingFromValidators: ValidatorsState? = nil

		var accountDepositSetting: DepositSettingState? = nil
		var accountDepositExceptions: DepositExceptionsState? = nil

		var proofs: TransactionReviewProofs.State? = nil
	}

	func sections(for summary: ExecutionSummary, networkID: NetworkID) async throws -> Sections? {
		let userAccounts = try await extractUserAccounts(summary.encounteredEntities)

		let allWithdrawAddresses = summary.accountWithdraws.values.flatMap { $0 }.map(\.resourceAddress)
		let allDepositAddresses = summary.accountDeposits.values.flatMap { $0 }.map(\.resourceAddress)
		// Prepoluate with all resource addresses from withdraw and deposit.
		let allAddresses: IdentifiedArrayOf<ResourceAddress> = try (allWithdrawAddresses + allDepositAddresses)
			.map { try $0.asSpecific() }
			.asIdentifiable()

		func resourcesInfo(_ resourceAddresses: [ResourceAddress]) async throws -> ResourcesInfo {
			var newlyCreatedMetadata = Dictionary(uniqueKeysWithValues: resourceAddresses.compactMap { resourceAddress in
				summary.metadataOfNewlyCreatedEntities[resourceAddress.address].map { (resourceAddress, ResourceInfo.right(.init($0))) }
			})

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
				guard !summary.accountDeposits.isEmpty || !summary.accountWithdraws.isEmpty else { return nil }
			}

			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let dAppAddresses = summary.encounteredEntities.filter { $0.entityType() == .globalGenericComponent }
			let dAppsUsed: TransactionReviewDappsUsed.State? = try await extractDapps(dAppAddresses, unknownTitle: L10n.TransactionReview.unknownComponents)

			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let proofs = try await exctractProofs(summary.presentedProofs)

			return Sections(
				withdrawals: withdrawals,
				dAppsUsed: dAppsUsed,
				deposits: deposits,
				proofs: proofs
			)

		case let .poolContribution(poolAddresses, poolContributions):
			// All resources that are part of the pool
			let resourceAddresses = try poolContributions.flatMap(\.contributedResources.keys).map {
				try ResourceAddress(validatingAddress: $0)
			}

			let allAddresses = allAddresses + resourceAddresses.asIdentifiable()
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let dApps = await extractDappEntities(poolAddresses)

			let perPoolUnitDapps = perPoolUnitDapps(dApps, poolInteractions: poolContributions)

			// Extract Contributing to Pools section
			let pools: TransactionReviewPools.State? = try await extractDapps(dApps, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Withdrawals section
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract Deposits section, passing in poolcontributions so that pool units can be updated
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				poolContributions: poolContributions.aggregated,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				contributingToPools: pools
			)

		case let .poolRedemption(poolAddresses, poolRedemptions):
			// All resources that are part of the pool
			let resourceAddresses = try poolRedemptions.flatMap(\.redeemedResources.keys).map {
				try ResourceAddress(validatingAddress: $0)
			}

			let allAddresses = allAddresses + resourceAddresses.asIdentifiable()
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let dApps = await extractDappEntities(poolAddresses)

			let perPoolUnitDapps = perPoolUnitDapps(dApps, poolInteractions: poolRedemptions)

			// Extract Contributing to Pools section
			let pools: TransactionReviewPools.State? = try await extractDapps(dApps, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Withdrawals section, passing in poolRedemptions so that withdrawn pool units can be updated
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				poolRedemptions: poolRedemptions.aggregated,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				resourceAssociatedDapps: perPoolUnitDapps,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				redeemingFromPools: pools
			)

		case let .validatorStake(validatorAddresses: validatorAddresses, validatorStakes: validatorStakes):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract validators
			let stakingToValidators = try await extractValidators(for: validatorAddresses)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				validatorStakes: validatorStakes.aggregated,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				stakingToValidators: stakingToValidators
			)

		case let .validatorUnstake(validatorAddresses, validatorUnstakes, claimsNonFungibleData):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)

			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract validators
			let unstakingFromValidators = try await extractValidators(for: validatorAddresses)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				unstakeData: claimsNonFungibleData,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				unstakingFromValidators: unstakingFromValidators
			)

		case let .validatorClaim(validatorAddresses, _):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try? await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws.aggregated,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let claimingFromValidators = try await extractValidators(for: validatorAddresses)

			let deposits = try? await extractDeposits(
				accountDeposits: summary.accountDeposits.aggregated,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
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

			let resourcePreferenceChanges = try resourcePreferencesUpdates.mapKeyValues(
				AccountAddress.init(validatingAddress:),
				fValue: { try $0.mapKeys(ResourceAddress.init(validatingAddress:)) }
			)
			let defaultDepositRuleChanges = try depositModeUpdates.mapKeys(AccountAddress.init(validatingAddress:))
			let authorizedDepositorsAdded = try authorizedDepositorsAdded.mapKeys(AccountAddress.init(validatingAddress:))
			let authorizedDepositorsRemoved = try authorizedDepositorsRemoved.mapKeys(AccountAddress.init(validatingAddress:))

			let allAccountAddress = Set(authorizedDepositorsAdded.keys)
				.union(authorizedDepositorsRemoved.keys)
				.union(defaultDepositRuleChanges.keys)
				.union(resourcePreferenceChanges.keys)

			let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork() // TODO: Use general one

			let validAccounts = allAccountAddress.compactMap { address in
				userAccounts.first { $0.address == address }
			}

			let accountDepositSetting = extractAccountDepositSetting(
				for: validAccounts,
				defaultDepositRuleChanges: defaultDepositRuleChanges
			)
			let accountDepositExceptions = try await extractAccountDepositExceptions(
				for: validAccounts,
				resourcePreferenceChanges: resourcePreferenceChanges,
				authorizedDepositorsAdded: authorizedDepositorsAdded,
				authorizedDepositorsRemoved: authorizedDepositorsRemoved
			)

			return Sections(
				accountDepositSetting: accountDepositSetting,
				accountDepositExceptions: accountDepositExceptions
			)
		}
	}

	private func extractUserAccounts(_ allAddress: [EngineToolkit.Address]) async throws -> [Account] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

		return allAddress
			.compactMap {
				try? $0.asSpecific()
			}
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

	private func extractDapps<Kind: SpecificEntityType>(
		_ addresses: [EngineToolkit.Address],
		unknownTitle: (Int) -> String
	) async throws -> TransactionReviewDapps<Kind>.State? {
		let dApps = await extractDappEntities(addresses)
		return try await extractDapps(dApps, unknownTitle: unknownTitle)
	}

	private func extractDapps<Kind: SpecificEntityType>(
		_ dAppEntities: [(address: EngineToolkit.Address, entity: DappEntity?)],
		unknownTitle: (Int) -> String
	) async throws -> TransactionReviewDapps<Kind>.State? {
		let knownDapps = dAppEntities.compactMap(\.entity).asIdentifiable()
		let unknownDapps = try dAppEntities.filter { $0.entity == nil }
			.map { try $0.address.asSpecific() as SpecificAddress<Kind> }.asIdentifiable()

		guard knownDapps.count + unknownDapps.count > 0 else { return nil }

		return .init(knownDapps: knownDapps, unknownDapps: unknownDapps, unknownTitle: unknownTitle)
	}

	private func extractDappEntities(_ addresses: [EngineToolkit.Address]) async -> [(address: EngineToolkit.Address, entity: DappEntity?)] {
		await addresses.asyncMap {
			await (address: $0, entity: try? extractDappEntity($0.asSpecific()))
		}
	}

	private func extractDappEntity(_ entity: Address) async throws -> DappEntity {
		let dAppDefinitionAddress = try await onLedgerEntitiesClient.getDappDefinitionAddress(entity)
		let metadata = try await onLedgerEntitiesClient.getDappMetadata(dAppDefinitionAddress, validatingDappEntity: entity)
		let isAuthorized = await authorizedDappsClient.isDappAuthorized(dAppDefinitionAddress)
		return DappEntity(id: dAppDefinitionAddress, metadata: metadata, isAuthorized: isAuthorized)
	}

	private func exctractProofs(_ accountProofs: [EngineToolkit.Address]) async throws -> TransactionReviewProofs.State? {
		let proofs = try await accountProofs
			.map { try ResourceAddress(validatingAddress: $0.addressString()) }
			.asyncMap(extractProofInfo)
		guard !proofs.isEmpty else { return nil }

		return TransactionReviewProofs.State(proofs: .init(uniqueElements: proofs))
	}

	private func extractProofInfo(_ address: ResourceAddress) async throws -> ProofEntity {
		try await ProofEntity(
			id: address,
			metadata: onLedgerEntitiesClient.getResource(address, metadataKeys: .dappMetadataKeys).metadata
		)
	}

	private func extractWithdrawals(
		accountWithdraws: [String: [ResourceIndicator]],
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolRedemptions: [TrackedPoolRedemption] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [ResourceBalance]] = [:]

		for (accountAddress, resources) in accountWithdraws {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))
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

			withdrawals[account, default: []].append(contentsOf: transfers)
		}

		guard !withdrawals.isEmpty else { return nil }

		let withdrawalAccounts = withdrawals.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}.asIdentifiable()

		return .init(accounts: withdrawalAccounts, enableCustomizeGuarantees: false)
	}

	private func extractDeposits(
		accountDeposits: [String: [ResourceIndicator]],
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolContributions: [TrackedPoolContribution] = [],
		validatorStakes: [TrackedValidatorStake] = [],
		unstakeData: [UnstakeDataEntry] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		let defaultDepositGuarantee = await appPreferencesClient.getPreferences().transaction.defaultDepositGuarantee

		var deposits: [Account: [ResourceBalance]] = [:]

		for (accountAddress, accountDeposits) in accountDeposits {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))
			let transfers = try await accountDeposits.asyncFlatMap {
				try await transferInfo(
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
			}

			deposits[account, default: []].append(contentsOf: transfers)
		}

		let depositAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value)) }
			.asIdentifiable()

		guard !depositAccounts.isEmpty else { return nil }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty
		return .init(accounts: depositAccounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	func extractValidators(for addresses: [EngineToolkit.Address]) async throws -> ValidatorsState? {
		guard !addresses.isEmpty else { return nil }

		let generalAddresses = try addresses.map { try $0.asGeneral() }

		let validators = try await onLedgerEntitiesClient.getEntities(addresses: generalAddresses, metadataKeys: .resourceMetadataKeys)
			.compactMap { entity -> ValidatorState? in
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
		for validAccounts: [Profile.Network.Account],
		defaultDepositRuleChanges: [AccountAddress: AccountDefaultDepositRule]
	) -> DepositSettingState? {
		let depositSettingChanges: [TransactionReview.DepositSettingChange] = validAccounts.compactMap { account in
			guard let depositRuleChange = defaultDepositRuleChanges[account.address] else { return nil }
			return .init(account: account, ruleChange: depositRuleChange)
		}

		guard !depositSettingChanges.isEmpty else { return nil }

		return .init(changes: IdentifiedArray(uncheckedUniqueElements: depositSettingChanges))
	}

	func extractAccountDepositExceptions(
		for validAccounts: [Profile.Network.Account],
		resourcePreferenceChanges: [AccountAddress: [ResourceAddress: ResourcePreferenceUpdate]],
		authorizedDepositorsAdded: [AccountAddress: [ResourceOrNonFungible]],
		authorizedDepositorsRemoved: [AccountAddress: [ResourceOrNonFungible]]
	) async throws -> DepositExceptionsState? {
		let exceptionChanges: [DepositExceptionsChange] = try await validAccounts.asyncCompactMap { account in
			let resourcePreferenceChanges = try await resourcePreferenceChanges[account.address]?
				.asyncMap { resourcePreference in
					try await DepositExceptionsChange.ResourcePreferenceChange(
						resource: onLedgerEntitiesClient.getResource(resourcePreference.key),
						change: resourcePreference.value
					)
				} ?? []

			let authorizedDepositorChanges = try await {
				var changes: [DepositExceptionsChange.AllowedDepositorChange] = []
				if let authorizedDepositorsAdded = authorizedDepositorsAdded[account.address] {
					let added = try await authorizedDepositorsAdded.asyncMap { resourceOrNonFungible in
						let resourceAddress = try resourceOrNonFungible.resourceAddress()
						return try await DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .added
						)
					}
					changes.append(contentsOf: added)
				}
				if let authorizedDepositorsRemoved = authorizedDepositorsRemoved[account.address] {
					let removed = try await authorizedDepositorsRemoved.asyncMap { resourceOrNonFungible in
						let resourceAddress = try resourceOrNonFungible.resourceAddress()
						return try await DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .removed
						)
					}
					changes.append(contentsOf: removed)
				}

				return changes
			}()

			guard !resourcePreferenceChanges.isEmpty || !authorizedDepositorChanges.isEmpty else { return nil }

			return DepositExceptionsChange(
				account: account,
				resourcePreferenceChanges: IdentifiedArray(uncheckedUniqueElements: resourcePreferenceChanges),
				allowedDepositorChanges: IdentifiedArray(uncheckedUniqueElements: authorizedDepositorChanges)
			)
		}

		guard !exceptionChanges.isEmpty else { return nil }

		return DepositExceptionsState(changes: IdentifiedArray(uncheckedUniqueElements: exceptionChanges))
	}

	private func perPoolUnitDapps(
		_ dappEntities: [(address: EngineToolkit.Address, entity: TransactionReview.DappEntity?)],
		poolInteractions: [some TrackedPoolInteraction]
	) -> ResourceAssociatedDapps {
		Dictionary(uniqueKeysWithValues: dappEntities.compactMap { data -> (ResourceAddress, OnLedgerEntity.Metadata)? in
			let poolUnitResource: ResourceAddress? = try? poolInteractions
				.first(where: { $0.poolAddress == data.address })?
				.poolUnitsResourceAddress
				.asSpecific()

			guard let poolUnitResource,
			      let dAppMetadata = data.entity?.metadata
			else {
				return nil
			}

			return (poolUnitResource, dAppMetadata)
		})
	}
}

extension TransactionReview {
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
		unstakeData: [UnstakeDataEntry] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		type: TransferType,
		defaultDepositGuarantee: RETDecimal = 1
	) async throws -> [ResourceBalance] {
		let resourceAddress: ResourceAddress = try resourceQuantifier.resourceAddress.asSpecific()

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
					amount: source.amount,
					guarantee: nil
				)

				return [.init(resource: resource, details: .fungible(details))]
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

extension [String: [ResourceIndicator]] {
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

	public mutating func add(_ other: Self) {
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
	public func adding(_ other: Self) -> Self {
		switch (self, other) {
		case let (.guaranteed(amount), .guaranteed(otherAmount)):
			return .guaranteed(amount: amount + otherAmount)
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return self
		}
	}
}

extension NonFungibleResourceIndicator {
	public func adding(_ other: Self) -> Self {
		switch (self, other) {
		case let (.byIds(ids), .byIds(otherIds)):
			return .byIds(ids: ids + otherIds)
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return self
		}
	}
}
