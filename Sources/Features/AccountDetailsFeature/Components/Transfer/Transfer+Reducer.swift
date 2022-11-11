import ComposableArchitecture

// MARK: - AccountDetails.Transfer
public extension AccountDetails {
	struct Transfer: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.dismissTransferButtonTapped)):
				return .run { send in
					await send(.delegate(.dismissTransfer))
				}
			case .delegate:
				return .none
			}
		}
	}
}
