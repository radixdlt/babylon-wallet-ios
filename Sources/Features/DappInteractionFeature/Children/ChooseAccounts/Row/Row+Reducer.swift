import FeaturePrelude

// MARK: - ChooseAccounts.Row
/// Namespace for Row
public extension ChooseAccounts {
	struct Row: Sendable, ReducerProtocol {
		public init() {}
	}
}

public extension ChooseAccounts.Row {
	func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
}
