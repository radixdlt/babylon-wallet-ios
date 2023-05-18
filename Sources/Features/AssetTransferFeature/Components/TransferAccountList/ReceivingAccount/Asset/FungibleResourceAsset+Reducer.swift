import FeaturePrelude

// MARK: - ReceivingAccount
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress

		public var id: ID {
			resource.resourceAddress
		}

		public var balance: BigDecimal {
			resource.amount
		}

		// Transfered resource
		public let resource: AccountPortfolio.FungibleResource

		// Mutable state

		// amount has to be string to allow setting the max value while editting
		public var transferAmountStr: String
		public var transferAmount: BigDecimal?
		// Total transfer sum for the given resource
		public var totalTransferSum: BigDecimal

		init(resource: AccountPortfolio.FungibleResource, transferAmount: BigDecimal?, totalTransferSum: BigDecimal) {
			self.transferAmount = transferAmount
			self.transferAmountStr = transferAmount?.formatWithoutRounding() ?? ""
			self.totalTransferSum = totalTransferSum
			self.resource = resource
		}

		init(resource: AccountPortfolio.FungibleResource) {
			self.init(resource: resource, transferAmount: nil, totalTransferSum: .zero)
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
		case let .amountChanged(transferAmountStr):
			state.transferAmountStr = transferAmountStr

			if let value = try? BigDecimal(localizedFromString: transferAmountStr) {
				state.transferAmount = value
			} else {
				state.transferAmount = nil
			}
			return .send(.delegate(.amountChanged))

		case .maxAmountTapped:
			let sumOfOthers = state.totalTransferSum - (state.transferAmount ?? .zero)
			let remainingAmount = max(state.balance - sumOfOthers, 0)
			state.transferAmount = remainingAmount
			state.transferAmountStr = remainingAmount.droppingTrailingZeros.formatWithoutRounding()
			return .send(.delegate(.amountChanged))

		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
