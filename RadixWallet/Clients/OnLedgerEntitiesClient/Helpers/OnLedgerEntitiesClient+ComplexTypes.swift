import Foundation
import Sargon

extension OnLedgerEntitiesClient {
	struct ResourceEntityNotFound: Swift.Error {
		let address: String
	}

	struct FailedToGetDataForAllNFTs: Swift.Error {}
	struct FailedToGetPoolUnitDetails: Swift.Error {}
	struct StakeUnitAddressMismatch: Swift.Error {}
	struct MissingTrackedValidatorStake: Swift.Error {}
	struct MissingPositiveTotalSupply: Swift.Error {}
	struct InvalidStakeClaimToken: Swift.Error {}
	struct MissingStakeClaimTokenData: Swift.Error {}

	// MARK: Fungibles

	func fungibleResourceBalance(
		_ resource: OnLedgerEntity.Resource,
		resourceQuantifier: FungibleResourceIndicator,
		poolContributions: [some TrackedPoolInteraction] = [] as [TrackedPoolContribution],
		validatorStakes: [TrackedValidatorStake] = [],
		entities: InteractionReview.Sections.ResourcesInfo = [:],
		resourceAssociatedDapps: InteractionReview.Sections.ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		defaultDepositGuarantee: Decimal192 = 1
	) async throws -> KnownResourceBalance {
		let amount = resourceQuantifier.amount
		let resourceAddress = resource.resourceAddress

		let guarantee: TransactionGuarantee? = { () -> TransactionGuarantee? in
			guard case let .predicted(predictedAmount) = resourceQuantifier else { return nil }
			let guaranteedAmount = defaultDepositGuarantee * predictedAmount.value
			return .init(
				amount: guaranteedAmount,
				percentage: defaultDepositGuarantee,
				instructionIndex: predictedAmount.instructionIndex,
				resourceAddress: resourceAddress,
				resourceDivisibility: resource.divisibility
			)
		}()

		return try await fungibleResourceBalance(
			resource,
			resourceAmount: .exact(.init(nominalAmount: amount)),
			guarantee: guarantee,
			networkID: networkID
		)
	}

	func fungibleResourceBalance(
		_ resource: OnLedgerEntity.Resource,
		resourceAmount: ResourceAmount,
		guarantee: TransactionGuarantee? = nil,
		poolContributions: [some TrackedPoolInteraction] = [] as [TrackedPoolContribution],
		validatorStakes: [TrackedValidatorStake] = [],
		entities: InteractionReview.Sections.ResourcesInfo = [:],
		resourceAssociatedDapps: InteractionReview.Sections.ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		defaultDepositGuarantee: Decimal192 = 1
	) async throws -> KnownResourceBalance {
		let resourceAddress = resource.resourceAddress

		@Dependency(\.resourcesVisibilityClient) var resourcesVisibilityClient
		let hiddenResources = try await resourcesVisibilityClient.getHidden()

		// Check if the fungible resource is a pool unit resource
		if await isPoolUnitResource(resource) {
			return try await poolUnit(
				resource,
				amount: resourceAmount,
				poolContributions: poolContributions,
				entities: entities,
				resourceAssociatedDapps: resourceAssociatedDapps,
				networkID: networkID,
				guarantee: guarantee,
				hiddenResources: hiddenResources
			)
		}

		// Check if the fungible resource is an LSU
		if let validator = await isLiquidStakeUnit(resource) {
			return try await liquidStakeUnit(
				resource,
				amount: resourceAmount,
				validator: validator,
				validatorStakes: validatorStakes,
				guarantee: guarantee
			)
		}

		// Normal fungible resource
		let isXRD = resourceAddress.isXRD(on: networkID)
		let isHidden = hiddenResources.contains(.fungible(resourceAddress))
		let details: KnownResourceBalance.Fungible = .init(isXRD: isXRD, amount: resourceAmount, guarantee: guarantee)

		return .init(resource: resource, details: .fungible(details), isHidden: isHidden)
	}

	private func poolUnit(
		_ resource: OnLedgerEntity.Resource,
		amount: ResourceAmount,
		poolContributions: [some TrackedPoolInteraction] = [],
		entities: InteractionReview.Sections.ResourcesInfo = [:],
		resourceAssociatedDapps: InteractionReview.Sections.ResourceAssociatedDapps? = nil,
		networkID: NetworkID,
		guarantee: TransactionGuarantee?,
		hiddenResources: [ResourceIdentifier]
	) async throws -> KnownResourceBalance {
		let resourceAddress = resource.resourceAddress

		if let poolContribution = poolContributions.first(where: { $0.poolUnitsResourceAddress == resourceAddress }) {
			guard let amount = amount.exactAmount?.nominalAmount else {
				fatalError()
			}
			// If this transfer does not contain all the pool units, scale the resource amounts pro rata
			let adjustmentFactor = amount != poolContribution.poolUnitsAmount ? (amount / poolContribution.poolUnitsAmount) : 1
			var xrdResource: OwnedResourcePoolDetails.ResourceWithRedemptionValue?
			var nonXrdResources: [OwnedResourcePoolDetails.ResourceWithRedemptionValue] = []
			for (address, resourceAmount) in poolContribution.resourcesInInteraction {
				guard let entity = entities[address] else {
					throw ResourceEntityNotFound(address: resourceAddress.address)
				}

				let resource = OwnedResourcePoolDetails.ResourceWithRedemptionValue(
					resource: .init(resourceAddress: address, metadata: entity.metadata),
					redemptionValue: .exact(.init(nominalAmount: resourceAmount * adjustmentFactor))
				)

				if address.isXRD(on: networkID) {
					xrdResource = resource
				} else {
					nonXrdResources.append(resource)
				}
			}

			let isHidden = hiddenResources.contains(.poolUnit(poolContribution.poolAddress))

			return .init(
				resource: resource,
				details: .poolUnit(.init(
					details: .init(
						address: poolContribution.poolAddress,
						dAppName: resourceAssociatedDapps?[resourceAddress]?.name,
						poolUnitResource: .init(resource: resource, amount: .exact(.init(nominalAmount: amount))),
						xrdResource: xrdResource,
						nonXrdResources: nonXrdResources
					),
					guarantee: guarantee
				)),
				isHidden: isHidden
			)
		} else {
			guard let details = try await getPoolUnitDetails(resource, forAmount: amount) else {
				throw FailedToGetPoolUnitDetails()
			}

			let isHidden = hiddenResources.contains(.poolUnit(details.address))

			return .init(
				resource: resource,
				details: .poolUnit(.init(
					details: details,
					guarantee: guarantee
				)),
				isHidden: isHidden
			)
		}
	}

	private func liquidStakeUnit(
		_ resource: OnLedgerEntity.Resource,
		amount: ResourceAmount,
		validator: OnLedgerEntity.Validator,
		validatorStakes: [TrackedValidatorStake] = [],
		guarantee: TransactionGuarantee?
	) async throws -> KnownResourceBalance {
		let worth: ResourceAmount
		if validatorStakes.isEmpty {
			guard let totalSupply = resource.totalSupply, totalSupply.isPositive else {
				throw MissingPositiveTotalSupply()
			}

			worth = amount.adjustedNominalAmount { $0 * validator.xrdVaultBalance / totalSupply }
		} else {
			guard let exactAmount = amount.exactAmount else {
				fatalError()
			}
			if let stake = validatorStakes.first(where: { $0.validatorAddress == validator.address }) {
				guard stake.liquidStakeUnitAddress == validator.stakeUnitResourceAddress else {
					throw StakeUnitAddressMismatch()
				}
				// Distribute the worth in proportion to the amounts, if needed
				if stake.liquidStakeUnitAmount == exactAmount.nominalAmount {
					worth = .exact(.init(nominalAmount: stake.xrdAmount))
				} else {
					worth = .exact(.init(nominalAmount: (exactAmount.nominalAmount / stake.liquidStakeUnitAmount) * stake.xrdAmount))
				}
			} else {
				throw MissingTrackedValidatorStake()
			}
		}

		let details = KnownResourceBalance.LiquidStakeUnit(
			resource: resource,
			amount: amount,
			worth: worth,
			validator: validator,
			guarantee: guarantee
		)

		return .init(resource: resource, details: .liquidStakeUnit(details))
	}

	// MARK: Non-fungibles

	func nonFungibleResourceBalances(
		_ resourceInfo: InteractionReview.Sections.ResourceInfo,
		resourceAddress: ResourceAddress,
		ids: [NonFungibleLocalId],
		unstakeData: [NonFungibleGlobalId: UnstakeData] = [:],
		newlyCreatedNonFungibles: [NonFungibleGlobalId] = []
	) async throws -> [KnownResourceBalance] {
		let result: [KnownResourceBalance]

		switch resourceInfo {
		case let .left(resource):
			@Dependency(\.resourcesVisibilityClient) var resourcesVisibilityClient
			let hiddenResources = try await resourcesVisibilityClient.getHidden()

			let existingTokenIds = ids.filter { id in
				!newlyCreatedNonFungibles.contains { newId in
					newId.resourceAddress == resourceAddress && newId.nonFungibleLocalId == id
				}
			}

			let newTokens = ids.filter { id in
				newlyCreatedNonFungibles.contains { newId in
					newId.resourceAddress == resourceAddress && newId.nonFungibleLocalId == id
				}
			}.map {
				OnLedgerEntity.NonFungibleToken(resourceAddress: resourceAddress, nftID: $0, nftData: nil)
			}

			let tokens = try await getNonFungibleTokenData(.init(
				resource: resourceAddress,
				nonFungibleIds: existingTokenIds.map {
					NonFungibleGlobalID(
						resourceAddress: resourceAddress,
						nonFungibleLocalId: $0
					)
				}
			)) + newTokens

			if let stakeClaimValidator = await isStakeClaimNFT(resource) {
				result = try [stakeClaim(
					resource,
					stakeClaimValidator: stakeClaimValidator,
					unstakeData: unstakeData,
					tokens: tokens
				)]
			} else {
				result = tokens.map { token in
					let isHidden = hiddenResources.contains(.nonFungible(token.id.resourceAddress))
					return KnownResourceBalance(resource: resource, details: .nonFungible(token), isHidden: isHidden)
				}

				guard result.count == ids.count else {
					throw FailedToGetDataForAllNFTs()
				}
			}

		case let .right(newEntityMetadata):
			// A newly created non-fungible resource
			let resource = OnLedgerEntity.Resource(resourceAddress: resourceAddress, metadata: newEntityMetadata)

			// Newly minted tokens
			result = ids
				.map { localId in
					NonFungibleGlobalID(
						resourceAddress: resourceAddress,
						nonFungibleLocalId: localId
					)
				}
				.map { id in
					KnownResourceBalance(resource: resource, details: .nonFungible(.init(id: id, data: nil)), isHidden: false)
				}

			guard result.count == ids.count else {
				throw FailedToGetDataForAllNFTs()
			}
		}

		return result
	}

	func stakeClaim(
		_ resource: OnLedgerEntity.Resource,
		stakeClaimValidator: OnLedgerEntity.Validator,
		unstakeData: [NonFungibleGlobalId: UnstakeData],
		tokens: [OnLedgerEntity.NonFungibleToken]
	) throws -> KnownResourceBalance {
		let stakeClaimTokens: [OnLedgerEntitiesClient.StakeClaim] = if unstakeData.isEmpty {
			try tokens.map { token in
				guard let data = token.data else {
					throw InvalidStakeClaimToken()
				}

				guard let claimAmount = data.claimAmount, token.id.resourceAddress == resource.resourceAddress else {
					throw InvalidStakeClaimToken()
				}

				return OnLedgerEntitiesClient.StakeClaim(
					validatorAddress: stakeClaimValidator.address,
					token: token,
					claimAmount: .init(nominalAmount: claimAmount),
					reamainingEpochsUntilClaim: data.claimEpoch.map { Int($0) - Int(resource.atLedgerState.epoch) }
				)
			}
		} else {
			try tokens.map { token in
				guard let data = unstakeData[token.id] else {
					throw MissingStakeClaimTokenData()
				}

				return OnLedgerEntitiesClient.StakeClaim(
					validatorAddress: stakeClaimValidator.address,
					token: token,
					claimAmount: .init(nominalAmount: data.claimAmount),
					reamainingEpochsUntilClaim: nil
				)
			}
		}

		return .init(
			resource: resource,
			details: .stakeClaimNFT(.init(
				canClaimTokens: false,
				stakeClaimTokens: .init(
					resource: resource,
					stakeClaims: stakeClaimTokens.asIdentified()
				),
				validatorName: stakeClaimValidator.metadata.name
			))
		)
	}
}

extension InteractionReview.Sections.ResourceInfo {
	var metadata: OnLedgerEntity.Metadata {
		switch self {
		case let .left(resource):
			resource.metadata
		case let .right(metadata):
			metadata
		}
	}
}
