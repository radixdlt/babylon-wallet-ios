import FeaturePrelude

// MARK: - ReceivingAccount
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
		public var id: ID {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress

		// amount has to be string to allow setting the max value while editting
		public var amountStr: String
		public var amount: BigDecimal?

		// Total sum for this given resource
		public var totalSum: BigDecimal
		public let balance: BigDecimal

		init(resourceAddress: ResourceAddress, amount: BigDecimal?, totalSum: BigDecimal, balance: BigDecimal) {
			self.amount = amount
			self.amountStr = amount?.formatWithoutRounding() ?? ""
			self.totalSum = totalSum
			self.resourceAddress = resourceAddress
			self.balance = balance
		}

		init(resourceAddress: ResourceAddress, totalSum: BigDecimal, balance: BigDecimal = 100) {
			self.init(
				resourceAddress: resourceAddress,
				amount: nil,
				totalSum: totalSum,
				balance: balance
			)
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
		case let .amountChanged(amountStr):
			state.amountStr = amountStr

			if let value = try? BigDecimal(localizedFromString: amountStr) {
				state.amount = value
			} else {
				state.amount = nil
			}
			return .send(.delegate(.amountChanged))
		case .maxAmountTapped:
			// Calculate the max allowed amount by taking into account the total sum of
			// the resource across different accounts.
			let sumOfOthers = state.totalSum - (state.amount ?? .zero)
			let remainingAmount = max(state.balance - sumOfOthers, 0)
			state.amount = remainingAmount
			state.amountStr = remainingAmount.droppingTrailingZeros.formatWithoutRounding()
			return .none
		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
