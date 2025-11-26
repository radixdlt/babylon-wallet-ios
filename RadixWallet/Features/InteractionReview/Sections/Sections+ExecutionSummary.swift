import Sargon

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

			newlyCreatedMetadata.merge(existingResourceDetails) { $1 }

			return newlyCreatedMetadata
		}

		switch summary.detailedClassification {
		case nil:
			return nil

		case let .securifyEntity(entityAddresses):
			guard let entityAddress = entityAddresses.first,
			      let entity = try await extractEntity(entityAddress) else { return nil }

			let shield = try SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entityAddress)

			return Common.SectionsData(
				shieldUpdate: .init(
					entity: entity,
					shield: shield
				)
			)

		case let .accessControllerRecovery(acAddresses):
			guard let acAddress = acAddresses.first else {
				return nil
			}
			let entity = try SargonOs.shared.entityByAccessControllerAddress(address: acAddress)
			let shield = try SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entity.asGeneral.address)

			return Common.SectionsData(
				shieldUpdate: .init(
					entity: entity,
					shield: shield
				)
			)

		case let .accessControllerConfirmTimedRecovery(acAddresses):
			guard let acAddress = acAddresses.first else {
				return nil
			}
			let entity = try SargonOs.shared.entityByAccessControllerAddress(address: acAddress)
			let shield = try SargonOs.shared.provisionalSecurityStructureOfFactorSourcesFromAddressOfAccountOrPersona(addressOfAccountOrPersona: entity.asGeneral.address)

			return Common.SectionsData(
				confirmShieldUpdate: .init(
					entity: entity,
					shield: shield
				)
			)

		case let .accessControllerStopTimedRecovery(acAddresses):
			let stopRecovery: Common.Accounts.State? = try await extractStopTimedRecovery(acAddresses: acAddresses)

			return Common.SectionsData(
				stopTimedRecovery: stopRecovery
			)

		case .general, .transfer:
			do {
				let resourcesInfo = try await resourcesInfo(allAddresses.elements)
				let withdrawals = try await extractWithdrawals(
					accountWithdraws: summary.withdrawals,
					newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
					entities: resourcesInfo,
					networkID: networkID
				)

				let dappAddresses = extractDappAddresses(encounteredAddresses: summary.encounteredAddresses)
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
			} catch {
				print("error \(error)")
				return nil
			}

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

		case let .deleteAccounts(accountAddresses):
			let deleteAccounts: Common.Accounts.State? = try await extractDeleteAccounts(accountAddresses: accountAddresses)

			var summary = summary
			for accountAddress in accountAddresses {
				summary.deposits[accountAddress] = nil
			}

			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let deposits = try await extractDeposits(
				accountDeposits: summary.deposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				networkID: networkID
			)

			return Common.SectionsData(
				deposits: deposits,
				accountDeletion: deleteAccounts
			)
		}
	}

	func extractUserAccounts(_ allAddress: [AccountAddress]) async throws -> [Common.ReviewAccount] {
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

	func extractEntity(_ address: AddressOfAccountOrPersona) async throws -> AccountOrPersona? {
		switch address {
		case let .account(accountAddress):
			let account = try await accountsClient.getAccountByAddress(accountAddress)
			return .account(account)
		case let .identity(identityAddress):
			let persona = try await personasClient.getPersona(id: identityAddress)
			return .persona(persona)
		}
	}

	func extractDappAddresses(encounteredAddresses: [ManifestEncounteredComponentAddress]) -> [Address] {
		encounteredAddresses.compactMap {
			switch $0 {
			case let .component(componentAddress):
				componentAddress.isGlobal ? componentAddress.asGeneral : nil
			case let .locker(lockerAddress):
				lockerAddress.asGeneral
			}
		}
	}

	func extractDapps(
		addresses: [Address],
		unknownTitle: (Int) -> String,
		showPossibleDappCalls: Bool = false
	) async throws -> InteractionReviewDapps<ComponentAddress>.State? {
		let dApps = await extractDappEntities(addresses)
		return try await extractDapps(
			dApps,
			unknownTitle: unknownTitle,
			showPossibleDappCalls: showPossibleDappCalls
		)
	}

	private func extractDapps<A: AddressProtocol>(
		_ dAppEntities: [(address: Address, entity: InteractionReview.DappEntity?)],
		unknownTitle: (Int) -> String,
		showPossibleDappCalls: Bool = false
	) async throws -> InteractionReviewDapps<A>.State? {
		let knownDapps = dAppEntities.compactMap(\.entity).asIdentified()
		let unknownDapps = try dAppEntities.filter { $0.entity == nil }
			.map { try $0.address.asSpecific(type: A.self) }.asIdentified()

		guard knownDapps.count + unknownDapps.count > 0 || showPossibleDappCalls else { return nil }

		return .init(
			knownDapps: knownDapps,
			unknownDapps: unknownDapps,
			unknownTitle: unknownTitle,
			showPossibleDappCalls: showPossibleDappCalls
		)
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

	func exctractProofs(_ accountProofs: [ResourceSpecifier]) async throws -> Common.Proofs.State? {
		let proofs = try await accountProofs
			.uniqued()
			.asyncMap(extractResourceBalanceInfo)
			.flatMap { $0 }
			.asyncMap(extractProofInfo)

		guard !proofs.isEmpty else { return nil }

		return Common.Proofs.State(kind: .transaction, proofs: proofs.asIdentified())
	}

	private func extractResourceBalanceInfo(specifier: ResourceSpecifier) async throws -> [(ResourceAddress, KnownResourceBalance.Details)] {
		switch specifier {
		case let .fungible(resourceAddress, amount):
			return [(
				resourceAddress,
				.fungible(
					.init(
						isXRD: resourceAddress.isXRD,
						amount: .exact(amount)
					)
				)
			)]
		case let .nonFungible(resourceAddress, ids):
			let globalIds = ids.map { NonFungibleGlobalId(resourceAddress: resourceAddress, nonFungibleLocalId: $0) }
			let tokens = try await onLedgerEntitiesClient.getNonFungibleTokenData(
				.init(resource: resourceAddress, nonFungibleIds: globalIds)
			)
			return tokens.map { (resourceAddress, .nonFungible(.token(.init(token: $0)))) }
		}
	}

	private func extractProofInfo(resourceAddress: ResourceAddress, details: KnownResourceBalance.Details) async throws -> Common.ProofEntity {
		try await Common.ProofEntity(
			resourceBalance: KnownResourceBalance(
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
			Common.Account.State(account: $0.key, transfers: $0.value, purpose: .withdrawal)
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
			.map { Common.Account.State(account: $0.key, transfers: $0.value, purpose: .deposit) }
			.asIdentified()

		guard !depositAccounts.isEmpty else { return nil }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty
		return .init(accounts: depositAccounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	private func extractDeleteAccounts(accountAddresses: [AccountAddress]) async throws -> Common.Accounts.State? {
		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts(accountAddresses)
		let accounts = try accountAddresses
			.map {
				let account = try userAccounts.account(for: $0)
				return Common.Account.State(
					account: account,
					transfers: [],
					purpose: .accountDeletion
				)
			}
			.asIdentified()

		return .init(accounts: accounts, enableCustomizeGuarantees: false)
	}

	private func extractStopTimedRecovery(acAddresses: [AccessControllerAddress]) async throws -> Common.Accounts.State? {
		guard let acAddress = acAddresses.first else { return nil }

		// Get the entity (account or persona) from access controller address
		let entity = try SargonOs.shared.entityByAccessControllerAddress(address: acAddress)

		// Extract account address - currently only accounts are supported for timed recovery
		let accountAddress = try entity.asAccount().accountAddress

		let userAccounts: [Common.ReviewAccount] = try await extractUserAccounts([accountAddress])
		let account = try userAccounts.account(for: accountAddress)

		let accountState = Common.Account.State(
			account: account,
			transfers: [],
			purpose: .stopTimedRecovery
		)

		return .init(accounts: [accountState].asIdentified(), enableCustomizeGuarantees: false)
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
	) -> Common.DepositSettingState? {
		let depositSettingChanges: [Common.DepositSettingChange] = validAccounts.compactMap { account in
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
	) async throws -> Common.DepositExceptionsState? {
		let exceptionChanges: [Common.DepositExceptionsChange] = try await validAccounts.asyncCompactMap { account in
			let resourcePreferenceChanges = try await resourcePreferenceChanges[account.address]?
				.asyncMap { resourcePreference in
					try await Common.DepositExceptionsChange.ResourcePreferenceChange(
						resource: onLedgerEntitiesClient.getResource(resourcePreference.key),
						change: resourcePreference.value
					)
				} ?? []

			let authorizedDepositorChanges = try await {
				var changes: [Common.DepositExceptionsChange.AllowedDepositorChange] = []
				if let authorizedDepositorsAdded = authorizedDepositorsAdded[account.address] {
					let added = try await authorizedDepositorsAdded.asyncMap { resourceOrNonFungible in
						let resourceAddress = resourceOrNonFungible.resourceAddress
						return try await Common.DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .added
						)
					}
					changes.append(contentsOf: added)
				}
				if let authorizedDepositorsRemoved = authorizedDepositorsRemoved[account.address] {
					let removed = try await authorizedDepositorsRemoved.asyncMap { resourceOrNonFungible in
						let resourceAddress = resourceOrNonFungible.resourceAddress
						return try await Common.DepositExceptionsChange.AllowedDepositorChange(
							resource: onLedgerEntitiesClient.getResource(resourceAddress),
							change: .removed
						)
					}
					changes.append(contentsOf: removed)
				}

				return changes
			}()

			guard !resourcePreferenceChanges.isEmpty || !authorizedDepositorChanges.isEmpty else { return nil }

			return Common.DepositExceptionsChange(
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
				return try await [.known(onLedgerEntitiesClient.fungibleResourceBalance(
					resource,
					resourceQuantifier: source,
					poolContributions: poolInteractions,
					validatorStakes: validatorStakes,
					entities: entities,
					resourceAssociatedDapps: resourceAssociatedDapps,
					networkID: networkID,
					defaultDepositGuarantee: defaultDepositGuarantee
				))]
			case let .right(newEntityMetadata):
				// A newly created fungible resource

				let resource: OnLedgerEntity.Resource = .init(
					resourceAddress: resourceAddress,
					metadata: newEntityMetadata
				)

				let details: KnownResourceBalance.Fungible = .init(
					isXRD: false,
					amount: .exact(source.amount),
					guarantee: nil
				)

				return [.known(.init(resource: resource, details: .fungible(details), isHidden: false))]
			}

		case let .nonFungible(_, indicator):
			return try await onLedgerEntitiesClient.nonFungibleResourceBalances(
				resourceInfo,
				resourceQuantifier: indicator,
				resourceAddress: resourceAddress,
				unstakeData: unstakeData,
				newlyCreatedNonFungibles: newlyCreatedNonFungibles
			)
			.map(\.toResourceBalance)
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
		case .fungible(_, .guaranteed), .nonFungible(_, .guaranteed):
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
		case let (.guaranteed(ids), .guaranteed(otherIds)):
			return .guaranteed(ids: ids + otherIds)
		default:
			assertionFailure("Cannot sum up the predicted amounts")
			return self
		}
	}
}
