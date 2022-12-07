import ComposableArchitecture
import ErrorQueue
import ProfileClient

// MARK: - DappConnectionRequest
public struct DappConnectionRequest: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \State.chooseAccounts!, action: /Action.child .. Action.ChildAction.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { [rejectedRequest = state.request] send in
				await send(.delegate(.rejected(rejectedRequest)))
			}

		case .internal(.view(.continueButtonTapped)):
			state.chooseAccounts = .init(
				request: state.request
			)
			return .none


		case .child(.chooseAccounts(.delegate(.dismissChooseAccounts))):
			state.chooseAccounts = nil
			return .none

		case let .child(.chooseAccounts(.delegate(.finishedChoosingAccounts(chosenAccounts, _)))):
			state.chooseAccounts = nil
			return .run { [request = state.request] send in
				await send(.delegate(
					.finishedChoosingAccounts(chosenAccounts, request: request)
				))
			}

		case .child, .delegate:
			return .none
                }
	}
}
