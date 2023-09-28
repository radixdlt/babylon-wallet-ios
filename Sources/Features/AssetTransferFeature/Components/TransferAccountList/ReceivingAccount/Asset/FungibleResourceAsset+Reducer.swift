import FeaturePrelude

// MARK: - FungibleResourceAsset
public struct FungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = String

		public var id: ID {
			resource.resourceAddress.address
		}

		public var balance: RETDecimal {
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
		public var transferAmount: RETDecimal? = nil

		// Total transfer sum for the transferred resource
		public var totalTransferSum: RETDecimal

		public var focused: Bool = false

		init(resource: AccountPortfolio.FungibleResource, isXRD: Bool, totalTransferSum: RETDecimal = .zero) {
			self.resource = resource
			self.isXRD = isXRD
			self.totalTransferSum = totalTransferSum
		}
	}

	public enum ViewAction: Equatable, Sendable {
		case amountChanged(String)
		case maxAmountTapped
		case focusChanged(Bool)
		case removeTapped
	}

	public enum DelegateAction: Equatable, Sendable {
		case removed
		case amountChanged
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .amountChanged(transferAmountStr):
			state.transferAmountStr = transferAmountStr

			if let value = try? RETDecimal(formattedString: transferAmountStr), !value.isNegative() {
				state.transferAmount = value
			} else {
				state.transferAmount = nil
			}
			return .send(.delegate(.amountChanged))

		case .maxAmountTapped:
			let fee: RETDecimal = state.isXRD ? .temporaryStandardFee : .zero
			let sumOfOthers = state.totalTransferSum - (state.transferAmount ?? .zero)
			let remainingAmount = (state.balance - sumOfOthers - fee).clamped
			state.transferAmount = remainingAmount
			state.transferAmountStr = remainingAmount.formattedPlain(useGroupingSeparator: false)
			return .send(.delegate(.amountChanged))

		case let .focusChanged(focused):
			state.focused = focused
			return .none

		case .removeTapped:
			return .send(.delegate(.removed))
		}
	}
}
