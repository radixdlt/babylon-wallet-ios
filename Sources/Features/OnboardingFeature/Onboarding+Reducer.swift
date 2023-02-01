import CreateEntityFeature
import CreateProfileFeature
import FeaturePrelude

// MARK: - Onboarding
public struct Onboarding: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/Onboarding.State.createProfile,
				action: /Action.child .. Action.ChildAction.createProfile
			) {
				CreateProfileCoordinator()
			}
			.ifCaseLet(
				/Onboarding.State.createAccountCoordinator,
				action: /Action.child .. Action.ChildAction.createAccountCoordinator
			) {
				CreateAccountCoordinator()
			}
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.createAccountCoordinator(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}
		default:
			return .none
		}
	}
}
