import FeaturePrelude
import SharedModels

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resource: OnLedgerEntity.Resource
		let amount: RETDecimal?
		let isXRD: Bool

		public init(resource: OnLedgerEntity.Resource, amount: RETDecimal? = nil, isXRD: Bool) {
			self.resource = resource
			self.amount = amount
			self.isXRD = isXRD
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
