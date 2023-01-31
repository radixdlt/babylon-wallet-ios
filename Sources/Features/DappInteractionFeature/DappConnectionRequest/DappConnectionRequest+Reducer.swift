import FeaturePrelude

// MARK: - DappConnectionRequest
public struct DappConnectionRequest: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { [rejectedRequest = state.request] send in
				await send(.delegate(.rejected(rejectedRequest)))
			}

		case .internal(.view(.continueButtonTapped)):
			return .run { [allowedRequest = state.request] send in
				await send(.delegate(.allowed(allowedRequest)))
			}

		case .child, .delegate:
			return .none
		}
	}
}
