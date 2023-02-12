import FeaturePrelude

// MARK: - Home.VisitHub
extension Home {
	public struct VisitHub: Sendable, ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.visitHubButtonTapped)):
				return .run { send in
					await send(.delegate(.displayHub))
				}
			case .delegate:
				return .none
			}
		}
	}
}
