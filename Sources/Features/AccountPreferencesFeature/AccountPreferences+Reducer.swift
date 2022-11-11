import ComposableArchitecture

// MARK: - AccountPreferences
public struct AccountPreferences: ReducerProtocol {
	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissAccountPreferences))
			}
		case .delegate:
			return .none
		}
	}
}
