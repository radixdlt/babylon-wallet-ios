import FeaturePrelude

extension Home {
	public struct Header: Sendable, ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.settingsButtonTapped)):
				return .run { send in
					await send(.delegate(.displaySettings))
				}
			case .delegate:
				return .none
			}
		}
	}
}
