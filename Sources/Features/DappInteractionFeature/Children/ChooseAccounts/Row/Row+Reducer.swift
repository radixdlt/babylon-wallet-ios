import FeaturePrelude

// MARK: - ChooseAccounts.Row
/// Namespace for Row
extension ChooseAccounts {
	struct Row: Sendable, ReducerProtocol {
		init() {}
	}
}

extension ChooseAccounts.Row {
	func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
}
