import FeaturePrelude

/*
 can balance and total sum be reused
 struct
*/

struct AResource {
        let totalSum: Double
        let balance: Double

        struct Account {
                let address: AccountAddress
                let amount: Double
        }
        let accounts: [Account]
}


// MARK: - ReceivingAccount
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
		public var id: ID {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress

                // amount has to be string to allow setting the max value while editting
		public var amount: String

                // Total sum for this given resource
		public var totalSum: BigDecimal
		public var balance: BigDecimal

		init(resourceAddress: ResourceAddress, amount: String, totalSum: BigDecimal, balance: BigDecimal) {
			self.amount = amount
			self.totalSum = totalSum
			self.resourceAddress = resourceAddress
			self.balance = balance
		}

		init(resourceAddress: ResourceAddress, totalSum: BigDecimal, balance: BigDecimal = 100) {
			self.init(resourceAddress: resourceAddress, amount: "", totalSum: totalSum, balance: balance)
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case removeTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case removed
                case amountChanged
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .amountChanged(amount):
			state.amount = amount
                        if !amount.isEmpty {
                                return .send(.delegate(.amountChanged))
                        }
                        return .none
		case .maxAmountTapped:
                        let remainingAmount = max(state.balance - state.totalSum, 0)
                        guard !state.amount.isEmpty else {
                                state.amount = remainingAmount.format()
                                return .none
                        }
                        let amount = try! BigDecimal(fromString: state.amount)
                        state.amount = (amount + remainingAmount).format()
			return .none
		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
