// MARK: - ResourceBalance
typealias IDResourceBalance = Identified<Tagged<ResourceBalance, UUID>, ResourceBalance>

extension ResourceBalance {
	var asIdentified: IDResourceBalance {
		.init(self, id: .init())
	}
}

// MARK: - ResourceBalance
enum ResourceBalance: Sendable, Hashable {
	case known(KnownResourceBalance)
	case unknown

	init(resource: OnLedgerEntity.Resource, details: KnownResourceBalance.Details, isHidden: Bool? = nil) {
		let knownResourceBalance = KnownResourceBalance(resource: resource, details: details, isHidden: isHidden)
		self = .known(knownResourceBalance)
	}
}

extension ResourceBalance {
	var resource: OnLedgerEntity.Resource? {
		switch self {
		case let .known(resourceBalance): resourceBalance.resource
		case .unknown: nil
		}
	}

	var details: KnownResourceBalance.Details? {
		switch self {
		case let .known(resourceBalance): resourceBalance.details
		case .unknown: nil
		}
	}

	var isHidden: Bool? {
		switch self {
		case let .known(resourceBalance): resourceBalance.isHidden
		case .unknown: nil
		}
	}
}

// MARK: - KnownResourceBalance
typealias IDKnownResourceBalance = Identified<Tagged<KnownResourceBalance, UUID>, KnownResourceBalance>

extension KnownResourceBalance {
	var asIdentified: IDKnownResourceBalance {
		.init(self, id: .init())
	}
}

extension KnownResourceBalance {
	var toResourceBalance: ResourceBalance {
		.known(self)
	}
}

// MARK: - KnownResourceBalance
struct KnownResourceBalance: Sendable, Hashable {
	let resource: OnLedgerEntity.Resource
	var details: Details

	/// Indicates whether the resource is hidden in user's profile.
	/// Value is optional since we won't check for cases that it doesn't matter.
	let isHidden: Bool?

	init(resource: OnLedgerEntity.Resource, details: Details, isHidden: Bool? = nil) {
		self.resource = resource
		self.details = details
		self.isHidden = isHidden
	}

	enum Details: Sendable, Hashable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case poolUnit(PoolUnit)
		case liquidStakeUnit(LiquidStakeUnit)
		case stakeClaimNFT(StakeClaimNFT)
	}

	struct Fungible: Sendable, Hashable {
		let isXRD: Bool
		let amount: ResourceAmount
		var guarantee: TransactionGuarantee?
	}

	struct LiquidStakeUnit: Sendable, Hashable {
		let resource: OnLedgerEntity.Resource
		let amount: Decimal192
		let worth: ExactResourceAmount
		let validator: OnLedgerEntity.Validator
		var guarantee: TransactionGuarantee?
	}

	typealias NonFungible = OnLedgerEntity.NonFungibleToken

	struct PoolUnit: Sendable, Hashable {
		let details: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		var guarantee: TransactionGuarantee?
	}

	struct StakeClaimNFT: Sendable, Hashable {
		let validatorName: String?
		var stakeClaimTokens: Tokens
		let stakeClaimResource: OnLedgerEntity.Resource

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

		struct Tokens: Sendable, Hashable {
			let canClaimTokens: Bool
			let stakeClaims: IdentifiedArrayOf<OnLedgerEntitiesClient.StakeClaim>
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

	struct Amount: Sendable, Hashable {
		let amount: ResourceAmount
		let guaranteed: Decimal192?

		init(_ amount: ResourceAmount, guaranteed: Decimal192? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}

		init(_ amount: Decimal192, guaranteed: Decimal192? = nil) {
			self.init(.exact(.init(nominalAmount: amount)), guaranteed: guaranteed)
		}

		init(exactAmount: ExactResourceAmount, guaranteed: Decimal192? = nil) {
			self.init(.exact(exactAmount), guaranteed: guaranteed)
		}
	}
}
