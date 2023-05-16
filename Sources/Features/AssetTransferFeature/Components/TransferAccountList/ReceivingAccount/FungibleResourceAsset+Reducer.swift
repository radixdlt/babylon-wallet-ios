import FeaturePrelude

// MARK: - ReceivingAccount
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
		public var id: ID {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
		public var amount: String
		public var maxAmount: Double

		init(resourceAddress: ResourceAddress, amount: String, maxAmount: Double) {
			self.amount = amount
			self.maxAmount = maxAmount
			self.resourceAddress = resourceAddress
		}

		init(resourceAddress: ResourceAddress, maxAmount: Double) {
			self.init(resourceAddress: resourceAddress, amount: "0.00", maxAmount: maxAmount)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
	}
}
