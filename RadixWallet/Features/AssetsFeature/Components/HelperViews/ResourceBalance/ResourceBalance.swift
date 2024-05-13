public typealias IDResourceBalance = Identified<Tagged<ResourceBalance, UUID>, ResourceBalance>

extension ResourceBalance {
	public var asIdentified: IDResourceBalance {
		.init(self, id: .init())
	}
}

// MARK: - TransactionGuarantee + Codable
extension TransactionGuarantee: Codable {
	private enum CodingKeys: String, CodingKey {
		case amount
		case instructionIndex
		case resourceAddress
		case resourceDivisibility
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			amount: container.decode(Decimal192.self, forKey: .amount),
			instructionIndex: container.decode(UInt64.self, forKey: .instructionIndex),
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			resourceDivisibility: container.decodeIfPresent(UInt8.self, forKey: .resourceDivisibility)
		)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(amount, forKey: .amount)
		try container.encode(instructionIndex, forKey: .instructionIndex)
		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encodeIfPresent(resourceDivisibility, forKey: .resourceDivisibility)
	}
}

// MARK: - ResourceBalance
public struct ResourceBalance: Sendable, Hashable, Codable {
	public let resource: OnLedgerEntity.Resource
	public var details: Details

	public init(resource: OnLedgerEntity.Resource, details: Details) {
		self.resource = resource
		self.details = details
	}

	public enum Details: Sendable, Hashable, Codable {
		case fungible(Fungible)
		case nonFungible(NonFungible)
		case poolUnit(PoolUnit)
		case liquidStakeUnit(LiquidStakeUnit)
		case stakeClaimNFT(StakeClaimNFT)
	}

	public struct Fungible: Sendable, Hashable, Codable {
		public let isXRD: Bool
		public let amount: ResourceAmount
		public var guarantee: TransactionGuarantee?
	}

	public struct LiquidStakeUnit: Sendable, Hashable, Codable {
		public let resource: OnLedgerEntity.Resource
		public let amount: Decimal192
		public let worth: ResourceAmount
		public let validator: OnLedgerEntity.Validator
		public var guarantee: TransactionGuarantee?
	}

	public typealias NonFungible = OnLedgerEntity.NonFungibleToken

	public struct PoolUnit: Sendable, Hashable, Codable {
		public let details: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		public var guarantee: TransactionGuarantee?
	}

	public struct StakeClaimNFT: Sendable, Hashable, Codable {
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

		public struct Tokens: Sendable, Hashable, Codable {
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
		public let guaranteed: Decimal192?

		init(_ amount: ResourceAmount, guaranteed: Decimal192? = nil) {
			self.amount = amount
			self.guaranteed = guaranteed
		}

		init(_ amount: Decimal192, guaranteed: Decimal192? = nil) {
			self.init(.init(nominalAmount: amount), guaranteed: guaranteed)
		}
	}
}
