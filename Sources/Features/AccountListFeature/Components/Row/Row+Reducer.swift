import ComposableArchitecture

// MARK: - AccountList.Row
public extension AccountList {
	struct Row: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.copyAddressButtonTapped)):
				return .none
			case .internal(.view(.selected)):
				return .none
			}
		}
	}
}
