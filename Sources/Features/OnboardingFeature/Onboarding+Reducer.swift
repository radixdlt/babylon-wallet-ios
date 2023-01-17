import CreateAccountFeature
import FeaturePrelude
import ImportProfileFeature

// MARK: - Onboarding
public struct Onboarding: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/Onboarding.State.importProfile,
				action: /Action.child .. Action.ChildAction.importProfile
			) {
				ImportProfile()
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
