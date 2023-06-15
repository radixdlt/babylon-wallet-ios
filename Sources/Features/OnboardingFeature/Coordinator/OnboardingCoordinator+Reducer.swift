import CreateAccountFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case startup(OnboardingStartup.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init() {
			self = .startup(.init())
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralResult(TaskResult<EquatableHashable>)
	}

	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/OnboardingCoordinator.State.startup,
				action: /Action.child .. ChildAction.startup
			) {
				OnboardingStartup()
			}
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
		case .startup(.delegate(.setupNewUser)):
			state = .createAccountCoordinator(
				.init(
					config: .init(purpose: .firstAccountForNewProfile)
				)
			)
			return .none

		case .startup(.delegate(.completed)):
			return .send(.delegate(.completed))

		case .createAccountCoordinator(.delegate(.completed)):
			return .task {
				let result = await TaskResult<EquatableHashable> {
					try await onboardingClient.commitEphemeral()
				}
				return .internal(.commitEphemeralResult(result))
			}
		default:
			return .none
		}
	}
}
