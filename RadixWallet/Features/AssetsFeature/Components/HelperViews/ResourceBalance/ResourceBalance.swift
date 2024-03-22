public typealias IDResourceBalance = Identified<Tagged<ResourceBalance, UUID>, ResourceBalance>

extension ResourceBalance {
	public var asIdentified: IDResourceBalance {
		.init(self, id: .init())
	}
}

// MARK: - ResourceBalance
public struct ResourceBalance: Sendable, Hashable {
	public let resource: OnLedgerEntity.Resource
	public var details: Details

	public init(resource: OnLedgerEntity.Resource, details: Details) {
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

		init(_ amount: ResourceAmount, guaranteed: RETDecimal? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}

		init(_ amount: RETDecimal, guaranteed: RETDecimal? = nil) {
			self.init(.init(nominalAmount: amount), guaranteed: guaranteed)
		}
	}
}
