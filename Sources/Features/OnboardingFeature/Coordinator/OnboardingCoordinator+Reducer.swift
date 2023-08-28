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
		case completed(Profile.Network.Account?, accountRecoveryIsNeeded: Bool)
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralResult(TaskResult<Prelude.Unit>)
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
			return sendDelegateCompleted(state: state, accountRecoveryIsNeeded: false)

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

		case let .startup(.delegate(.completed(accountRecoveryIsNeeded))):
			return sendDelegateCompleted(state: state, accountRecoveryIsNeeded: accountRecoveryIsNeeded)

		case .createAccountCoordinator(.delegate(.completed)):
			return .task {
				let result = await TaskResult<Prelude.Unit> {
					try await onboardingClient.commitEphemeral()
				}
				return .internal(.commitEphemeralResult(result))
			}

		default:
			return .none
		}
	}

	private func sendDelegateCompleted(state: State, accountRecoveryIsNeeded: Bool) -> EffectTask<Action> {
		.send(.delegate(.completed(state.newAccount, accountRecoveryIsNeeded: accountRecoveryIsNeeded)))
	}
}

extension OnboardingCoordinator.State {
	fileprivate var newAccount: Profile.Network.Account? {
		guard
			let lastStepState = (/Self.createAccountCoordinator).extract(from: self)?.lastStepState,
			let newAccountCompletionState = (/CreateAccountCoordinator.Destinations.State.step3_completion).extract(from: lastStepState)
		else {
			return nil
		}

		return newAccountCompletionState.account
	}
}
