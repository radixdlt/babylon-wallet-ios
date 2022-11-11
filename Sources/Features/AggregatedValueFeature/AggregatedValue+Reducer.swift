import ComposableArchitecture

public struct AggregatedValue: ReducerProtocol {
	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.toggleVisibilityButtonTapped)):
			return .run { send in
				await send(.delegate(.toggleIsCurrencyAmountVisible))
			}
		case .delegate:
			return .none
		}
	}
}
