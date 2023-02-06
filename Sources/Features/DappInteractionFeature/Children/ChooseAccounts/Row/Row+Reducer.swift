import FeaturePrelude

// MARK: - ChooseAccounts.Row
/// Namespace for Row
extension ChooseAccounts {
	struct Row: Sendable, ReducerProtocol {
		init() {}
	}
}

extension ChooseAccounts.Row {
	func reduce(into _: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.view(.didSelect)):
			return .send(.delegate(.didSelect))
		}
	}
}
