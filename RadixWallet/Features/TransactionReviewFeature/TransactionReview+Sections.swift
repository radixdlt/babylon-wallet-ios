import Foundation

extension TransactionReview {
	// Either the resource from ledger or metadata extracted from the TX manifest
	typealias ResourceInfo = Either<OnLedgerEntity.Resource, OnLedgerEntity.Metadata>
	typealias ResourcesInfo = [ResourceAddress: ResourceInfo]
	typealias ResourceAssociatedDapps = [ResourceAddress: OnLedgerEntity.Metadata]

	public struct Sections: Sendable, Hashable {
		var withdrawals: TransactionReviewAccounts.State? = nil
		var dAppsUsed: TransactionReviewDappsUsed.State? = nil
		var deposits: TransactionReviewAccounts.State? = nil

		var contributingToPools: TransactionReviewPools.State? = nil
		var redeemingFromPools: TransactionReviewPools.State? = nil

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
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try? await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let dAppAddresses = summary.encounteredEntities.filter { $0.entityType() == .globalGenericComponent }
			let dAppsUsed: TransactionReviewDappsUsed.State? = try await extractDapps(dAppAddresses, unknownTitle: L10n.TransactionReview.unknownComponents)

			let deposits = try? await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let proofs = try? await exctractProofs(summary.presentedProofs)

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
			return nil

		case let .validatorUnstake(validatorAddresses, validatorUnstakes, claimsNonFungibleData):
			return nil

		case let .validatorClaim(validatorAddresses, validatorClaims):
			let resourcesInfo = try await resourcesInfo(allAddresses.elements)
			let withdrawals = try? await extractWithdrawals(
				accountWithdraws: summary.accountWithdraws,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			let deposits = try? await extractDeposits(
				accountDeposits: summary.accountDeposits,
				newlyCreatedNonFungibles: summary.newlyCreatedNonFungibles,
				entities: resourcesInfo,
				userAccounts: userAccounts,
				networkID: networkID
			)

			return Sections(
				withdrawals: withdrawals,
				deposits: deposits
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
		var withdrawals: [Account: [Transfer]] = [:]

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
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
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
					newlyCreatedNonFungibles: newlyCreatedNonFungibles,
					poolInteractions: poolContributions,
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

	func transferInfo(
		resourceQuantifier: ResourceIndicator,
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = [],
		poolInteractions: [some TrackedPoolInteraction] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		type: TransferType,
		defaultDepositGuarantee: RETDecimal = 1
	) async throws -> [Transfer] {
		let resourceAddress: ResourceAddress = try resourceQuantifier.resourceAddress.asSpecific()

		guard let resourceInfo = entities[resourceAddress] else {
			throw ResourceEntityNotFound(address: resourceAddress.address)
		}

		switch resourceQuantifier {
		case let .fungible(_, source):
			switch resourceInfo {
			case let .left(resource):
				return try await fungibleTransferInfo(
					resource,
					resourceQuantifier: source,
					poolContributions: poolInteractions,
					entities: entities,
					resourceAssociatedDapps: resourceAssociatedDapps,
					networkID: networkID,
					defaultDepositGuarantee: defaultDepositGuarantee
				)
			case let .right(newEntityMetadata):
				// A newly created fungible resource

				let resource: OnLedgerEntity.Resource = .init(
					resourceAddress: resourceAddress,
					metadata: newEntityMetadata
				)

				let details: Transfer.Details.Fungible = .init(
					isXRD: false,
					amount: source.amount,
					guarantee: nil
				)

				return [.init(resource: resource, details: .fungible(details))]
			}

		case let .nonFungible(_, indicator):
			return try await nonFungibleResourceTransfer(
				resourceInfo,
				resourceAddress: resourceAddress,
				resourceQuantifier: indicator,
				newlyCreatedNonFungibles: newlyCreatedNonFungibles
			)
		}
	}

	func fungibleTransferInfo(
		_ resource: OnLedgerEntity.Resource,
		resourceQuantifier: FungibleResourceIndicator,
		poolContributions: [some TrackedPoolInteraction] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		defaultDepositGuarantee: RETDecimal = 1
	) async throws -> [Transfer] {
		let amount = resourceQuantifier.amount
		let resourceAddress = resource.resourceAddress

		let guarantee: TransactionClient.Guarantee? = {
			guard case let .predicted(predictedAmount) = resourceQuantifier else { return nil }
			let guaranteedAmount = defaultDepositGuarantee * predictedAmount.value
			return .init(
				amount: guaranteedAmount,
				instructionIndex: predictedAmount.instructionIndex,
				resourceAddress: resourceAddress,
				resourceDivisibility: resource.divisibility
			)
		}()

		// Check if the fungible resource is a pool unit resource
		if await onLedgerEntitiesClient.isPoolUnitResource(resource) {
			return try await poolUnitTransfer(
				resource,
				amount: amount,
				poolContributions: poolContributions,
				entities: entities,
				resourceAssociatedDapps: resourceAssociatedDapps,
				networkID: networkID,
				guarantee: guarantee
			)
		}

		// Normal fungible resource
		let isXRD = resourceAddress.isXRD(on: networkID)
		let details: Transfer.Details.Fungible = .init(
			isXRD: isXRD,
			amount: amount,
			guarantee: guarantee
		)

		return [.init(resource: resource, details: .fungible(details))]
	}

	private func nonFungibleResourceTransfer(
		_ resourceInfo: ResourceInfo,
		resourceAddress: ResourceAddress,
		resourceQuantifier: NonFungibleResourceIndicator,
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = []
	) async throws -> [Transfer] {
		let ids = resourceQuantifier.ids
		let result: [Transfer]

		switch resourceInfo {
		case let .left(resource):
			let existingTokenIds = ids.filter { id in
				!newlyCreatedNonFungibles.contains { newId in
					newId.resourceAddress().asStr() == resourceAddress.address && newId.localId() == id
				}
			}

			let newTokens = try ids.filter { id in
				newlyCreatedNonFungibles.contains { newId in
					newId.resourceAddress().asStr() == resourceAddress.address && newId.localId() == id
				}
			}.map {
				try OnLedgerEntity.NonFungibleToken(resourceAddress: resourceAddress, nftID: $0, nftData: nil)
			}

			let tokens = try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
				resource: resourceAddress,
				nonFungibleIds: existingTokenIds.map {
					try NonFungibleGlobalId.fromParts(
						resourceAddress: resourceAddress.intoEngine(),
						nonFungibleLocalId: $0
					)
				}
			)) + newTokens

			let stakeClaimValidator = await onLedgerEntitiesClient.isStakeClaimNFT(resource)
			if let stakeClaimValidator {
				result = try stakeClaimTransfer(
					resource,
					stakeClaimValidator: stakeClaimValidator,
					tokens: tokens
				)
			} else {
				result = tokens.map { token in
					.init(resource: resource, details: .nonFungible(token))
				}

				guard result.count == ids.count else {
					throw FailedToGetDataForAllNFTs()
				}
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

			guard result.count == ids.count else {
				throw FailedToGetDataForAllNFTs()
			}
		}

		return result
	}

	private func poolUnitTransfer(
		_ resource: OnLedgerEntity.Resource,
		amount: RETDecimal,
		poolContributions: [some TrackedPoolInteraction] = [],
		entities: ResourcesInfo = [:],
		resourceAssociatedDapps: ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		guarantee: TransactionClient.Guarantee?
	) async throws -> [Transfer] {
		let resourceAddress = resource.resourceAddress

		if let poolContribution = try poolContributions.first(where: { try $0.poolUnitsResourceAddress.asSpecific() == resourceAddress }) {
			// If this transfer does not contain all the pool units, scale the resource amounts pro rata
			let adjustmentFactor = amount != poolContribution.poolUnitsAmount ? (amount / poolContribution.poolUnitsAmount) : 1
			var xrdResource: OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue?
			var nonXrdResources: [OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue] = []
			for (resourceAddress, resourceAmount) in poolContribution.resourcesInInteraction {
				let address = try ResourceAddress(validatingAddress: resourceAddress)

				guard let entity = entities[address] else {
					throw ResourceEntityNotFound(address: resourceAddress)
				}

				let resource = OnLedgerEntitiesClient.OwnedResourcePoolDetails.ResourceWithRedemptionValue(
					resource: .init(resourceAddress: address, metadata: entity.metadata),
					redemptionValue: resourceAmount * adjustmentFactor
				)

				if address.isXRD(on: networkID) {
					xrdResource = resource
				} else {
					nonXrdResources.append(resource)
				}
			}

			return try [.init(
				resource: resource,
				details: .poolUnit(.init(
					details: .init(
						address: poolContribution.poolAddress.asSpecific(),
						dAppName: resourceAssociatedDapps?[resourceAddress]?.name,
						poolUnitResource: .init(resource: resource, amount: amount),
						xrdResource: xrdResource,
						nonXrdResources: nonXrdResources
					),
					guarantee: guarantee
				))
			)]
		} else {
			guard let details = try await onLedgerEntitiesClient.getPoolUnitDetails(resource, forAmount: amount) else {
				throw FailedToGetPoolUnitDetails()
			}

			return [.init(
				resource: resource,
				details: .poolUnit(.init(
					details: details,
					guarantee: guarantee
				))
			)]
		}
	}

	private func stakeClaimTransfer(
		_ resource: OnLedgerEntity.Resource,
		stakeClaimValidator: OnLedgerEntity.Validator,
		tokens: [OnLedgerEntity.NonFungibleToken]
	) throws -> [Transfer] {
		struct InvalidStakeClaimToken: Error {}

		let stakeClaimTokens = try tokens.map { token in
			guard let data = token.data, let claimAmount = data.claimAmount else {
				throw InvalidStakeClaimToken()
			}
			return OnLedgerEntitiesClient.StakeClaim(
				validatorAddress: stakeClaimValidator.address,
				token: token,
				claimAmount: claimAmount,
				reamainingEpochsUntilClaim: data.claimEpoch.map { Int($0) - Int(resource.atLedgerState.epoch) }
			)
		}

		return [.init(
			resource: resource,
			details: .stakeClaimNFT(.init(
				canClaimTokens: false,
				stakeClaimTokens: .init(
					resource: resource,
					stakeClaims: stakeClaimTokens.asIdentifiable()
				),
				validatorName: stakeClaimValidator.metadata.name ?? L10n.TransactionReview.unknown
			))
		)]
	}
}

extension TransactionReview.ResourceInfo {
	var metadata: OnLedgerEntity.Metadata {
		switch self {
		case let .left(resource):
			resource.metadata
		case let .right(metadata):
			metadata
		}
	}
}
