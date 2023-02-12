import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, ReducerProtocol {
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
