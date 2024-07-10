import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Root: Sendable, Hashable {
			case startup(OnboardingStartup.State)
			case createAccountCoordinator(CreateAccountCoordinator.State)
		}

		public var root: Root

		public init() {
			self.root = .startup(.init())
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.appEventsClient) var appEventsClient

	public init() {}

	public var body: some ReducerOf<Self> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .startup(.delegate(.setupNewUser)):
			state.root = .createAccountCoordinator(
				.init(
					config: .init(purpose: .firstAccountForNewProfile)
				)
			)
			return .none

		case .startup(.delegate(.profileCreatedFromImportedBDFS)):
			return sendDelegateCompleted(state: state)

		case .startup(.delegate(.completed)):
			return sendDelegateCompleted(state: state)

		case .createAccountCoordinator(.delegate(.accountCreated)):
			appEventsClient.handleEvent(.walletCreated)
			return .run { _ in
				_ = await onboardingClient.finishOnboarding()
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
			}

		case .createAccountCoordinator(.delegate(.completed)):
			return sendDelegateCompleted(state: state)

		default:
			return .none
		}
	}

	private func sendDelegateCompleted(
		state: State
	) -> Effect<Action> {
		.send(.delegate(.completed))
	}
}
