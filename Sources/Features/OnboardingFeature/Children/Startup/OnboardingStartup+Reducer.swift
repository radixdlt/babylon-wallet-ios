import FeaturePrelude
import OnboardingClient

public struct OnboardingStartup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedNewWalletUser
		case selectedRestoreFromBackup
	}

	public enum DelegateAction: Sendable, Equatable {
		case setupNewUser
		case completed
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case restoreFromBackup(RestoreFromBackup.State)
		}

		public enum Action: Sendable, Equatable {
			case restoreFromBackup(RestoreFromBackup.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.restoreFromBackup, action: /Action.restoreFromBackup) {
				RestoreFromBackup()
			}
		}
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectedNewWalletUser:
			return .send(.delegate(.setupNewUser))
		case .selectedRestoreFromBackup:
			state.destination = .restoreFromBackup(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.restoreFromBackup(.delegate(.completed)))):
			return .send(.delegate(.completed))
		default:
			return .none
		}
	}
}
