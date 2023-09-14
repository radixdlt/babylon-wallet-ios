import FeaturePrelude

// MARK: - ManageSecurityStructureStart
public struct ManageSecurityStructureStart: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case simpleFlow
		case advancedFlow
	}

	public enum DelegateAction: Sendable, Equatable {
		case simpleFlow
		case advancedFlow
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .simpleFlow:
			return .send(.delegate(.simpleFlow))
		case .advancedFlow:
			return .send(.delegate(.advancedFlow))
		}
	}
}
