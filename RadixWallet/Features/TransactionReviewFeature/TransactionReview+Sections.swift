import Foundation

extension TransactionReview {
	public struct Sections: Sendable, Hashable {
		var withdrawals: TransactionReviewAccounts.State? = nil
		var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		var deposits: TransactionReviewAccounts.State? = nil

		var contributingToPools: TransactionReviewPools.State? = nil
		var redeemingFromPools: TransactionReviewPools.State? = nil

		var accountDepositSetting: DepositSettingState? = nil
		var accountDepositExceptions: DepositExceptionsState? = nil

		var proofs: TransactionReviewProofs.State? = nil

		let conforming: Bool
	}

	func sections(for summary: ExecutionSummary, networkID: NetworkID) async throws -> Sections {
		let userAccounts = try await extractUserAccounts(summary.encounteredEntities)

		switch summary.detailedManifestClass {
		case nil:
			return Sections(conforming: false)
		case .general, .transfer:
			let withdrawals = try? await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				metadataOfNewlyCreatedEntities: summary.metadataOfNewlyCreatedEntities,
				dataOfNewlyMintedNonFungibles: summary.dataOfNewlyMintedNonFungibles,
				addressesOfNewlyCreatedEntities: summary.addressesOfNewlyCreatedEntities,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let dAppAddresses = summary.encounteredEntities.filter { $0.entityType() == .globalGenericComponent }
			let dAppsUsed: TransactionReviewDappsUsed.State? = try await extractDapps(dAppAddresses, unknownTitle: L10n.TransactionReview.unknownComponents)

			let deposits = try? await extractDeposits(
				accountDeposits: summary.accountDeposits,
				metadataOfNewlyCreatedEntities: summary.metadataOfNewlyCreatedEntities,
				dataOfNewlyMintedNonFungibles: summary.dataOfNewlyMintedNonFungibles,
				addressesOfNewlyCreatedEntities: summary.addressesOfNewlyCreatedEntities,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let proofs = try? await exctractProofs(summary.presentedProofs)

			return Sections(
				withdrawals: withdrawals,
				dAppsUsed: dAppsUsed,
				deposits: deposits,
				proofs: proofs,
				conforming: true
			)

		case let .poolContribution(poolAddresses: poolAddresses, poolContributions: poolContributions):
			// Extract Withdrawals section
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract Contributing to Pools section
			let pools: TransactionReviewPools.State? = try await extractDapps(poolAddresses, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Deposits section, passing in poolcontributions so that pool units can be updated
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				poolContributions: poolContributions,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				contributingToPools: pools,
				conforming: true
			)

		case let .poolRedemption(poolAddresses: poolAddresses, poolRedemptions: poolRedemptions):
			// Extract Withdrawals section, passing in poolRedemptions so that withdrawn pool units can be updated
			let withdrawals = try await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				poolRedemptions: poolRedemptions,
				userAccounts: userAccounts,
				networkID: networkID
			)

			// Extract Redeeming from Pools section
			let pools: TransactionReviewPools.State? = try await extractDapps(poolAddresses, unknownTitle: L10n.TransactionReview.unknownPools)

			// Extract Deposits section
			let deposits = try await extractDeposits(
				accountDeposits: summary.accountDeposits,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits,
				redeemingFromPools: pools,
				conforming: true
			)

		case let .validatorStake(validatorAddresses: validatorAddresses, validatorStakes: validatorStakes):
			return .init(conforming: false)
		case let .validatorUnstake(validatorAddresses: validatorAddresses, validatorUnstakes: validatorUnstakes):
			return .init(conforming: false)
		case let .validatorClaim(validatorAddresses: validatorAddresses, validatorClaims: validatorClaims):
			return .init(conforming: false)
		case let .accountDepositSettingsUpdate(resourcePreferencesUpdates: resourcePreferencesUpdates, depositModeUpdates: depositModeUpdates, authorizedDepositorsAdded: authorizedDepositorsAdded, authorizedDepositorsRemoved: authorizedDepositorsRemoved):

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
				accountDepositExceptions: accountDepositExceptions,
				conforming: true
			)
		}
	}

	private func updateAccounts(
		_ accounts: inout IdentifiedArrayOf<TransactionReviewAccount.State>,
		with interactions: [some TrackedPoolInteraction],
		networkID: NetworkID
	) async throws {
		let aggregatedInteractions = interactions.aggregated

		let resourceEntities = try await resourceEntities(for: aggregatedInteractions)

		for contribution in aggregatedInteractions {
			let resourceAddress = try contribution.poolUnitsResourceAddress.asSpecific() as ResourceAddress

			guard let poolUnitResource = resourceEntities.first(where: { $0.resourceAddress == resourceAddress }) else { continue }

			// The resources in the pool
			let poolResources = try poolResources(for: contribution.resourcesInInteraction, entities: resourceEntities, networkID: networkID)

			for account in accounts {
				for transfer in account.transfers {
					if transfer.resource.id == resourceAddress, case let .fungible(details) = transfer.details {
						var resources = poolResources

						// If this transfer does not contain all the pool units, scale the resource amounts pro rata
						if details.amount != contribution.poolUnitsAmount {
							let factor = details.amount / contribution.poolUnitsAmount
							for index in resources.indices {
								resources[index].amount *= factor // TODO: Round according to divisibility
							}
						}

						accounts[id: account.id]?.transfers[id: transfer.id]?.details = .poolUnit(.init(
							poolName: poolUnitResource.title,
							resources: resources,
							guarantee: transfer.fungibleGuarantee
						))
					}
				}
			}
		}
	}

	private func resourceEntities(for poolInteractions: [some TrackedPoolInteraction]) async throws -> [OnLedgerEntity.Resource] {
		let poolUnitAddresses = try poolInteractions.map(\.poolUnitsResourceAddress).map {
			try $0.asSpecific() as Address
		}
		let resourceAddresses = try poolInteractions.flatMap(\.resourcesInInteraction.keys).map {
			try Address(validatingAddress: $0)
		}

		// The entities for the pool units and the redeemed resources
		return try await onLedgerEntitiesClient.getEntities(
			addresses: poolUnitAddresses + resourceAddresses,
			metadataKeys: .poolUnitMetadataKeys
		)
		.compactMap(\.resource)
	}

	private func poolResources(for resources: [String: RETDecimal], entities: [OnLedgerEntity.Resource], networkID: NetworkID) throws -> [Transfer.Details.PoolUnit.Resource] {
		try resources
			.map { addressString, amount in
				let address = try ResourceAddress(validatingAddress: addressString)

				guard let entity = entities.first(where: { $0.id == address }) else {
					struct ResourceEntityNotFound: Error {
						let address: String
					}
					throw ResourceEntityNotFound(address: addressString)
				}

				return Transfer.Details.PoolUnit.Resource(
					isXRD: entity.resourceAddress.isXRD(on: networkID),
					symbol: entity.metadata.symbol,
					address: entity.resourceAddress,
					icon: entity.metadata.iconURL,
					amount: amount
				)
			}
	}

	private func extractUserAccounts(_ allAddress: [EngineToolkit.Address]) async throws -> [Account] {
		let userAccounts = try await accountsClient.getAccountsOnCurrentNetwork()

		return allAddress
			.compactMap {
				try? AccountAddress(validatingAddress: $0.addressString())
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
		let dApps = await addresses.asyncMap {
			await (address: $0, entity: try? extractDappEntity($0.asSpecific()))
		}
		let knownDapps = dApps.compactMap(\.entity).asIdentifiable()
		let unknownDapps = try dApps.filter { $0.entity == nil }
			.map { try $0.address.asSpecific() as SpecificAddress<Kind> }.asIdentifiable()

		guard knownDapps.count + unknownDapps.count > 0 else { return nil }

		return .init(knownDapps: knownDapps, unknownDapps: unknownDapps, unknownTitle: unknownTitle)
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
		metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]] = [:],
		dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]] = [:],
		addressesOfNewlyCreatedEntities: [EngineToolkit.Address] = [],
		poolRedemptions: [TrackedPoolRedemption] = [],
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		var withdrawals: [Account: [Transfer]] = [:]

		for (accountAddress, resources) in accountWithdraws {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))
			let transfers = try await resources.asyncFlatMap {
				try await transferInfo(
					resourceQuantifier: $0,
					metadataOfCreatedEntities: metadataOfNewlyCreatedEntities,
					dataOfNewlyMintedNonFungibles: dataOfNewlyMintedNonFungibles,
					createdEntities: addressesOfNewlyCreatedEntities,
					networkID: networkID,
					type: .exact
				)
			}

			withdrawals[account, default: []].append(contentsOf: transfers)
		}

		guard !withdrawals.isEmpty else { return nil }

		let withdrawalAccounts = withdrawals.map {
			TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value))
		}

		var accounts = IdentifiedArray(uniqueElements: withdrawalAccounts)

		if !poolRedemptions.isEmpty {
			try await updateAccounts(&accounts, with: poolRedemptions, networkID: networkID)
		}

		return .init(accounts: accounts, enableCustomizeGuarantees: false)
	}

	private func extractDeposits(
		accountDeposits: [String: [ResourceIndicator]],
		metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]] = [:],
		dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]] = [:],
		addressesOfNewlyCreatedEntities: [EngineToolkit.Address] = [],
		poolContributions: [TrackedPoolContribution] = [],
		userAccounts: [Account],
		networkID: NetworkID
	) async throws -> TransactionReviewAccounts.State? {
		let defaultDepositGuarantee = await appPreferencesClient.getPreferences().transaction.defaultDepositGuarantee

		var deposits: [Account: [Transfer]] = [:]

		for (accountAddress, accountDeposits) in accountDeposits {
			let account = try userAccounts.account(for: .init(validatingAddress: accountAddress))
			let transfers = try await accountDeposits.asyncFlatMap {
				try await transferInfo(
					resourceQuantifier: $0,
					metadataOfCreatedEntities: metadataOfNewlyCreatedEntities,
					dataOfNewlyMintedNonFungibles: dataOfNewlyMintedNonFungibles,
					createdEntities: addressesOfNewlyCreatedEntities,
					networkID: networkID,
					type: $0.transferType,
					defaultDepositGuarantee: defaultDepositGuarantee
				)
			}

			deposits[account, default: []].append(contentsOf: transfers)
		}

		var depositAccounts = deposits
			.filter { !$0.value.isEmpty }
			.map { TransactionReviewAccount.State(account: $0.key, transfers: .init(uniqueElements: $0.value)) }

		let requiresGuarantees = !depositAccounts.customizableGuarantees.isEmpty

		guard !depositAccounts.isEmpty else { return nil }

		var accounts = IdentifiedArray(uniqueElements: depositAccounts)

		if !poolContributions.isEmpty {
			try await updateAccounts(&accounts, with: poolContributions, networkID: networkID)
		}
		return .init(accounts: accounts, enableCustomizeGuarantees: requiresGuarantees)
	}

	func transferInfo(
		resourceQuantifier: ResourceIndicator,
		metadataOfCreatedEntities: [String: [String: MetadataValue?]]?,
		dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: Data]],
		createdEntities: [EngineToolkit.Address],
		networkID: NetworkID,
		type: TransferType,
		defaultDepositGuarantee: RETDecimal = 1
	) async throws -> [Transfer] {
		let resourceAddress: ResourceAddress = try resourceQuantifier.resourceAddress.asSpecific()

		func resourceInfo() async throws -> Either<OnLedgerEntity.Resource, [String: MetadataValue?]> {
			if let newlyCreatedMetadata = metadataOfCreatedEntities?[resourceAddress.address] {
				.right(newlyCreatedMetadata)
			} else {
				try await .left(onLedgerEntitiesClient.getResource(resourceAddress))
			}
		}

		typealias NonFungibleToken = OnLedgerEntity.NonFungibleToken

		func existingTokenInfo(_ ids: [NonFungibleLocalId], for resourceAddress: ResourceAddress) async throws -> [NonFungibleToken] {
			try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
				resource: resourceAddress,
				nonFungibleIds: ids.map {
					try NonFungibleGlobalId.fromParts(
						resourceAddress: resourceAddress.intoEngine(),
						nonFungibleLocalId: $0
					)
				}
			))
		}

		switch resourceQuantifier {
		case let .fungible(_, source):
			let amount = switch source {
			case let .guaranteed(amount):
				amount
			case let .predicted(predictedAmount):
				predictedAmount.value
			}

			switch try await resourceInfo() {
			case let .left(resource):
				// A fungible resource existing on ledger
				let isXRD = resourceAddress.isXRD(on: networkID)

				func guarantee() -> TransactionClient.Guarantee? {
					guard case let .predicted(predictedAmount) = source else { return nil }
					let guaranteedAmount = defaultDepositGuarantee * amount
					return .init(
						amount: guaranteedAmount,
						instructionIndex: predictedAmount.instructionIndex,
						resourceAddress: resourceAddress,
						resourceDivisibility: resource.divisibility
					)
				}

				let details: Transfer.Details.Fungible = .init(
					isXRD: isXRD,
					amount: amount,
					guarantee: guarantee()
				)

				return [.init(resource: resource, details: .fungible(details))]

			case let .right(newEntityMetadata):
				// A newly created fungible resource

				let resource: OnLedgerEntity.Resource = .init(
					resourceAddress: resourceAddress,
					metadata: newEntityMetadata
				)

				let details: Transfer.Details.Fungible = .init(
					isXRD: false,
					amount: amount,
					guarantee: nil
				)

				return [.init(resource: resource, details: .fungible(details))]
			}

		case let .nonFungible(_, indicator):
			let ids = indicator.ids
			let result: [Transfer]

			switch try await resourceInfo() {
			case let .left(resource):
				// A non-fungible resource existing on ledger

				// Existing or newly minted tokens
				//
				// This is not entirely correct, we should not attempt to fetch NFT data the tokens
				// that are about to be minted, but current RET does not retur the information about the freshly minted tokens anymore.
				// Needs to be addressed in RET.
				result = try await existingTokenInfo(ids, for: resource.resourceAddress).map { token in
					.init(resource: resource, details: .nonFungible(token))
				}

			case let .right(newEntityMetadata):
				// A newly created non-fungible resource
				let resource = OnLedgerEntity.Resource(resourceAddress: resourceAddress, metadata: newEntityMetadata)

				// Newly minted tokens
				result = try ids
					.map { localId in
						try NonFungibleGlobalId.fromParts(resourceAddress: resourceAddress.intoEngine(), nonFungibleLocalId: localId)
					}
					.map { id in
						Transfer(resource: resource, details: .nonFungible(.init(id: id, data: nil)))
					}
			}

			guard result.count == ids.count else {
				struct FailedToGetDataForAllNFTs: Error {}
				throw FailedToGetDataForAllNFTs()
			}

			return result
		}
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
}
