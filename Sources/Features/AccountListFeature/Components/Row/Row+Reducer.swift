import ComposableArchitecture

// MARK: - AccountList.Row
public extension AccountList {
	struct Row: ReducerProtocol {
		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.user(.copyAddress)):
				return .none
			case .internal(.user(.didSelect)):
				return .none
			}
		}
	}
}
