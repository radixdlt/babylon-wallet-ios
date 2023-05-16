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
		public var balance: Double

		init(resourceAddress: ResourceAddress, amount: String, maxAmount: Double, balance: Double) {
			self.amount = amount
			self.maxAmount = maxAmount
			self.resourceAddress = resourceAddress
			self.balance = balance
		}

		init(resourceAddress: ResourceAddress, maxAmount: Double, balance: Double = 100) {
			self.init(resourceAddress: resourceAddress, amount: "", maxAmount: maxAmount, balance: balance)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case removeTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case removed
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .amountChanged(amount):
			state.amount = amount
			return .none
		case .maxAmountTapped:
			state.amount = "\(state.maxAmount)"
			return .none
		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
