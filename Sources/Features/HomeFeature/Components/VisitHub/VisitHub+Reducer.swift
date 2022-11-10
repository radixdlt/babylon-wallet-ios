import ComposableArchitecture

// MARK: - Home.VisitHub
public extension Home {
	struct VisitHub: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.visitHubButtonTapped)):
				return Effect(value: .delegate(.displayHub))
			case .delegate:
				return .none
			}
		}
	}
}
