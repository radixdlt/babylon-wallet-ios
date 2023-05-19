import FeaturePrelude

// MARK: - FungibleResourceAsset
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress

		public var id: ID {
			resource.resourceAddress
		}

		public var balance: BigDecimal {
			resource.amount
		}

		public var totalExceedsBalance: Bool {
			totalTransferSum > balance
		}

		// Transfered resource
		public let resource: AccountPortfolio.FungibleResource
		public let isXRD: Bool

		// MARK: - Mutable state

		public var transferAmountStr: String = ""
		public var transferAmount: BigDecimal? = nil

		// Total transfer sum for the transferred resource
		public var totalTransferSum: BigDecimal

		init(resource: AccountPortfolio.FungibleResource, isXRD: Bool, totalTransferSum: BigDecimal) {
			self.resource = resource
			self.isXRD = isXRD
			self.totalTransferSum = totalTransferSum
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
