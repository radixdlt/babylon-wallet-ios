import ComposableArchitecture

public extension Home {
	struct Header: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.settingsButtonTapped)):
				return Effect(value: .delegate(.displaySettings))
			case .delegate:
				return .none
			}
		}
	}
}
