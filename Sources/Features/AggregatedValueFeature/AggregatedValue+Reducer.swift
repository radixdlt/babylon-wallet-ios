import ComposableArchitecture

public struct AggregatedValue: ReducerProtocol {
	public init() {}

	public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.toggleVisibilityButtonTapped)):
			return Effect(value: .delegate(.toggleIsCurrencyAmountVisible))
		case .delegate:
			return .none
		}
	}
}
