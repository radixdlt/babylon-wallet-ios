import ComposableArchitecture

// MARK: - AccountPreferences
public struct AccountPreferences: ReducerProtocol {
	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return Effect(value: .delegate(.dismissAccountPreferences))
		case .delegate:
			return .none
		}
	}
}
