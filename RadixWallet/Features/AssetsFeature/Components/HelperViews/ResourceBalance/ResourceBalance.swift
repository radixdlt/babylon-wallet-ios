// MARK: - ResourceBalance
public struct ResourceBalance: Sendable, Hashable, Identifiable {
	public var id: AnyHashable { _id?.wrapped ?? .init(self) }
	private let _id: SendableAnyHashable?

	public let resource: OnLedgerEntity.Resource
	public var details: Details

	public init(resource: OnLedgerEntity.Resource, details: Details, id: some Hashable & Sendable) {
		self._id = .init(wrapped: id)
		self.resource = resource
		self.details = details
	}

	public init(resource: OnLedgerEntity.Resource, details: Details) {
		self._id = nil
		self.resource = resource
		self.details = details
	}

	public enum Details: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case poolUnit(PoolUnit)
		case liquidStakeUnit(LiquidStakeUnit)
		case stakeClaimNFT(StakeClaimNFT)
	}

	public struct Fungible: Sendable, Hashable {
		public let isXRD: Bool
		public let amount: ResourceAmount
		public var guarantee: TransactionClient.Guarantee?
	}

	public struct LiquidStakeUnit: Sendable, Hashable {
		public let resource: OnLedgerEntity.Resource
		public let amount: RETDecimal
		public let worth: ResourceAmount
		public let validator: OnLedgerEntity.Validator
		public var guarantee: TransactionClient.Guarantee?
	}

	public typealias NonFungible = OnLedgerEntity.NonFungibleToken

	public struct PoolUnit: Sendable, Hashable {
		public let details: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		public var guarantee: TransactionClient.Guarantee?
	}

	public struct StakeClaimNFT: Sendable, Hashable {
		public let validatorName: String?
		public var stakeClaimTokens: Tokens
		public let stakeClaimResource: OnLedgerEntity.Resource

		var resourceMetadata: OnLedgerEntity.Metadata {
			stakeClaimResource.metadata
		}

		init(
			canClaimTokens: Bool,
			stakeClaimTokens: OnLedgerEntitiesClient.NonFungibleResourceWithTokens,
			validatorName: String? = nil,
			selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>? = nil
		) {
			self.validatorName = validatorName
			self.stakeClaimResource = stakeClaimTokens.resource
			self.stakeClaimTokens = .init(
				canClaimTokens: canClaimTokens,
				stakeClaims: stakeClaimTokens.stakeClaims,
				selectedStakeClaims: selectedStakeClaims
			)
		}

		public struct Tokens: Sendable, Hashable {
			public let canClaimTokens: Bool
			public let stakeClaims: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim>
			var selectedStakeClaims: IdentifiedArrayOf<NonFungibleGlobalId>?

			var unstaking: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
				stakeClaims.filter(\.isUnstaking)
			}

			var readyToBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
				stakeClaims.filter(\.isReadyToBeClaimed)
			}

			var toBeClaimed: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim> {
				stakeClaims.filter(\.isToBeClaimed)
			}
		}
	}

	// Helper types

	public struct Amount: Sendable, Hashable {
		public let amount: ResourceAmount
		public let guaranteed: RETDecimal?

		init(_ amount: RETDecimal, guaranteed: RETDecimal? = nil) {
			self.init(.init(nominalAmount: amount), guaranteed: guaranteed)
		}

		init(_ amount: ResourceAmount, guaranteed: RETDecimal? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}
	}
}

extension ResourceBalance {
	var viewState: ViewState {
		switch details {
		case let .fungible(details):
			.fungible(.init(resource: resource, details: details))
		case let .nonFungible(details):
			.nonFungible(.init(resource: resource, details: details))
		case let .liquidStakeUnit(details):
			.lsu(.init(resource: resource, details: details))
		case let .poolUnit(details):
			.poolUnit(.init(resource: resource, details: details))
		case let .stakeClaimNFT(details):
			.stakeClaimNFT(details)
		}
	}
}

private extension ResourceBalance.ViewState.Fungible {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.Fungible) {
		self.init(
			address: resource.resourceAddress,
			icon: .token(details.isXRD ? .xrd : .other(resource.metadata.iconURL)),
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount)
		)
	}
}

private extension ResourceBalance.ViewState.NonFungible {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.NonFungible) {
		self.init(
			id: details.id,
			resourceImage: resource.metadata.iconURL,
			resourceName: resource.metadata.name,
			nonFungibleName: details.data?.name
		)
	}
}

private extension ResourceBalance.ViewState.LSU {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.LiquidStakeUnit) {
		self.init(
			address: resource.resourceAddress,
			icon: resource.metadata.iconURL,
			title: resource.metadata.title,
			amount: .init(details.amount, guaranteed: details.guarantee?.amount),
			worth: details.worth,
			validatorName: details.validator.metadata.name
		)
	}
}

private extension ResourceBalance.ViewState.PoolUnit {
	init(resource: OnLedgerEntity.Resource, details: ResourceBalance.PoolUnit) {
		self.init(
			resourcePoolAddress: details.details.address,
			poolUnitAddress: resource.resourceAddress,
			poolIcon: resource.metadata.iconURL,
			poolName: resource.fungibleResourceName,
			amount: .init(details.details.poolUnitResource.amount, guaranteed: details.guarantee?.amount),
			dAppName: .success(details.details.dAppName),
			resources: .success(.init(resources: details.details))
//			resources: .success()
		)
	}
}
