import CreateEntityFeature
import FeaturePrelude

// MARK: - Onboarding
public struct OnboardingCoordinator: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/OnboardingCoordinator.State.importProfile,
				action: /Action.child .. Action.ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.newProfileThenAccountCoordinator,
				action: /Action.child .. Action.ChildAction.newProfileThenAccountCoordinator
			) {
				NewProfileThenAccountCoordinator()
			}
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.importProfile(.delegate(.imported))):
			return .run { send in
				await send(.delegate(.completed))
			}

		case .child(.newProfileThenAccountCoordinator(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}

		case .child(.newProfileThenAccountCoordinator(.delegate(.criticialErrorFailedToCommitEphemeralProfile))):
			fatalError("Failed to commit ephemeral profile")

		default:
			return .none
		}
	}
}
