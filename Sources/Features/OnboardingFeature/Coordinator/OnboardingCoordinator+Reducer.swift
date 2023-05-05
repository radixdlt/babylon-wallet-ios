import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case startup(Startup.State)
		case importProfile(ImportProfile.State)
		case restoreFromBackup(RestoreFromBackup.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .startup(.init())
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case startup(Startup.Action)
		case importProfile(ImportProfile.Action)
		case restoreFromBackup(RestoreFromBackup.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralResult(TaskResult<EquatableVoid>)
	}

	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/OnboardingCoordinator.State.startup,
				action: /Action.child .. ChildAction.startup
			) {
				Startup()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.importProfile,
				action: /Action.child .. ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.restoreFromBackup,
				action: /Action.child .. ChildAction.restoreFromBackup,
				then: {
					RestoreFromBackup()
				}
			)
			.ifCaseLet(
				/OnboardingCoordinator.State.createAccountCoordinator,
				action: /Action.child .. ChildAction.createAccountCoordinator
			) {
				CreateAccountCoordinator()
			}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .commitEphemeralResult(.success):
			return .send(.delegate(.completed))
		case let .commitEphemeralResult(.failure(error)):
			fatalError("Unable to use app, failed to commit profile, error: \(String(describing: error))")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .startup(.delegate(.importProfile)):
			state = .importProfile(.init())
			return .none
		case .startup(.delegate(.createFirstAccount)):
			state = .createAccountCoordinator(
				.init(
					config: .init(purpose: .firstAccountForNewProfile),
					displayIntroduction: { _ in false }
				)
			)
			return .none
		case .startup(.delegate(.loadFromBackup)):
			state = .restoreFromBackup(.init())
			return .none
		case .createAccountCoordinator(.delegate(.completed)):
			return .run { send in
				await send(.internal(.commitEphemeralResult(TaskResult {
					try await onboardingClient.commitEphemeral()
				})))
			}
		case .importProfile(.delegate(.imported)):
			return .send(.delegate(.completed))
		case .restoreFromBackup(.delegate(.completed)):
			return .send(.delegate(.completed))
		default:
			return .none
		}
	}
}
