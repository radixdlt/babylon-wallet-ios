import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public enum State: Equatable {
		case importProfile(ImportProfile.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .createAccountCoordinator(.init())
		}
	}

	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		case delegate(DelegateAction)
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
				action: /Action.child .. Action.ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.createAccountCoordinator,
				action: /Action.child .. Action.ChildAction.createAccountCoordinator
			) {
				CreateAccountCoordinator()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .createAccountCoordinator(.delegate(.completed)):
			return .send(.delegate(.completed))
		case .createAccountCoordinator(.delegate(.dismiss)):
			fatalError("not possible")
		case .importProfile(.delegate(.imported)):
			return .send(.delegate(.completed))
		}
	}
}

#if DEBUG
extension OnboardingCoordinator.State {
	public static let previewValue: Self = .init()
}
#endif
