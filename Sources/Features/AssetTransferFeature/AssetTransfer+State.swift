import FeaturePrelude

// MARK: - AssetTransfer.State
public extension AssetTransfer {
	// MARK: State
	struct State: Sendable, Hashable {
		public typealias From = OnNetwork.Account

		// TODO: declare union type for this in SharedModels
		public enum AssetToTransfer: Sendable, Hashable {
			case token(FungibleToken)
//			case nft(NonFungibleToken)
		}

		public enum To: Sendable, Hashable {
//			case account(OnNetwork.Account)
			case address(AccountAddress)

			var address: AccountAddress {
				switch self {
				case let .address(address):
					return address
				}
			}
		}

		public let from: From
		public var asset: AssetToTransfer
		public var amount: Decimal_?
		public var to: To?

		@PresentationStateOf<Destinations>
		public var destination

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
