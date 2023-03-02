import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public enum State: Hashable {
		case importProfile(ImportProfile.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .createAccountCoordinator(
				.init(
					config: .init(
						isFirstEntity: true,
						canBeDismissed: false,
						navigationButtonCTA: .goHome
					)
				)
			)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/OnboardingCoordinator.State.importProfile,
				action: /Action.child .. ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.createAccountCoordinator,
				action: /Action.child .. ChildAction.createAccountCoordinator
			) {
				CreateAccountCoordinator()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .createAccountCoordinator(.delegate(.completed)):
			return .send(.delegate(.completed))
		case .importProfile(.delegate(.imported)):
			return .send(.delegate(.completed))
		default: return .none
		}
	}
}

#if DEBUG
extension OnboardingCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
