import CreateAccountFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Root: Sendable, Hashable {
			case startup(OnboardingStartup.State)
			case createAccountCoordinator(CreateAccountCoordinator.State)
		}

		public var root: Root
		public let isMainnetLive: Bool

		public init(isMainnetLive: Bool) {
			self.isMainnetLive = isMainnetLive
			self.root = .startup(.init())
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(
			accountRecoveryIsNeeded: Bool,
			hasMainnetAccounts: Bool,
			isMainnetLive: Bool
		)
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralResult(TaskResult<HasMainnetAccounts>)
	}

	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child) {
			EmptyReducer()
				.ifCaseLet(/State.Root.startup, action: /ChildAction.startup) {
					OnboardingStartup()
				}
				.ifCaseLet(/State.Root.createAccountCoordinator, action: /ChildAction.createAccountCoordinator) {
					CreateAccountCoordinator()
				}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .commitEphemeralResult(.success(hasMainnetAccounts)):
			return sendDelegateCompleted(
				state: state,
				accountRecoveryIsNeeded: false,
				hasMainnetAccounts: hasMainnetAccounts
			)

		case let .commitEphemeralResult(.failure(error)):
			fatalError("Unable to use app, failed to commit profile, error: \(String(describing: error))")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .startup(.delegate(.setupNewUser)):
			state.root = .createAccountCoordinator(
				.init(
					config: .init(purpose: .firstAccountForNewProfile(mainnetIsLive: state.isMainnetLive))
				)
			)
			return .none

		case let .startup(.delegate(.completed(accountRecoveryIsNeeded, hasMainnetAccounts))):
			return sendDelegateCompleted(
				state: state,
				accountRecoveryIsNeeded: accountRecoveryIsNeeded,
				hasMainnetAccounts: hasMainnetAccounts
			)

		case .createAccountCoordinator(.delegate(.completed)):
			return .task {
				let result = await TaskResult<HasMainnetAccounts> {
					try await onboardingClient.commitEphemeral()
				}
				return .internal(.commitEphemeralResult(result))
			}

		default:
			return .none
		}
	}

	private func sendDelegateCompleted(
		state: State,
		accountRecoveryIsNeeded: Bool,
		hasMainnetAccounts: Bool
	) -> EffectTask<Action> {
		.send(.delegate(.completed(
			accountRecoveryIsNeeded: accountRecoveryIsNeeded,
			hasMainnetAccounts: hasMainnetAccounts,
			isMainnetLive: state.isMainnetLive
		)))
	}
}

public typealias HasMainnetAccounts = Bool
