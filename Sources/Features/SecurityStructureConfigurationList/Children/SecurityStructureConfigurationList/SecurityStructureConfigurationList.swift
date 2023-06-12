import FeaturePrelude

// MARK: - SecurityStructureConfigurationList
public struct SecurityStructureConfigurationList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case createNewStructure
	}

	public enum DelegateAction: Sendable, Equatable {
		case createNewStructure
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .createNewStructure:
			return .send(.delegate(.createNewStructure))
		}
	}
}
