import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingCoordinator
struct OnboardingCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var startup: OnboardingStartup.State

		@PresentationState
		var destination: Destination.State?

		init() {
			self.startup = .init()
		}
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case completed
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.createAccount, action: \.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.appEventsClient) var appEventsClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.startup, action: \.child.startup) {
			OnboardingStartup()
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .startup(.delegate(.setupNewUser)):
			state.destination = .createAccount(
				.init(
					config: .init(purpose: .firstAccountForNewProfile)
				)
			)
			return .none

		case .startup(.delegate(.profileCreatedFromImportedBDFS)):
			appEventsClient.handleEvent(.walletRestored)
			return .send(.delegate(.completed))

		case .startup(.delegate(.completed)):
			appEventsClient.handleEvent(.walletRestored)
			return .send(.delegate(.completed))

		default:
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .createAccount(.delegate(.completed)):
			return .send(.delegate(.completed))

		case .createAccount(.delegate(.accountCreated)):
			appEventsClient.handleEvent(.walletCreated)
			return .run { _ in
				_ = await onboardingClient.finishOnboarding()
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
			}

		default:
			return .none
		}
	}
}
