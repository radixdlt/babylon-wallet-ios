import FeaturePrelude

// MARK: - AssetTransfer.State
public extension AssetTransfer {
	// MARK: State
	struct State: Sendable, Equatable {
		public typealias From = OnNetwork.Account

		public enum AssetToTransfer: Sendable, Equatable {
			case token(FungibleToken)
//			case nft(NonFungibleToken)
		}

		public enum To: Sendable, Equatable {
//			case account(OnNetwork.Account)
			case address(AccountAddress)

			var address: String {
				switch self {
				case let .address(address):
					return address.address
				}
			}
		}

		public let from: From
		public var asset: AssetToTransfer
		public var amount: Decimal_?
		public var to: To?

		public init(
			from: From,
			asset: AssetToTransfer = .token(.xrd),
			amount: Decimal_? = nil,
			to: To? = nil
		) {
			self.from = from
			self.asset = asset
			self.amount = amount
			self.to = to
		}
	}
}
