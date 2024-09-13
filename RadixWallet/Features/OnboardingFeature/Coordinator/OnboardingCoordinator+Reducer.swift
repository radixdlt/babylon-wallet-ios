import ComposableArchitecture
import SwiftUI

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var startup: OnboardingStartup.State

		@PresentationState
		public var destination: Destination.State?

		public init() {
			self.startup = .init()
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case newProfileCreated
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case startup(OnboardingStartup.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case createAccount(CreateAccountCoordinator.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case createAccount(CreateAccountCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.createAccount, action: \.createAccount) {
				CreateAccountCoordinator()
			}
		}
	}

	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.appEventsClient) var appEventsClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.startup, action: \.child.startup) {
			OnboardingStartup()
		}

		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .newProfileCreated:
			state.destination = .createAccount(
				.init(
					config: .init(purpose: .firstAccountForNewProfile)
				)
			)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .startup(.delegate(.setupNewUser)):
			return .run { send in
				try await onboardingClient.createNewWallet()
				await send(.internal(.newProfileCreated))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .createAccount(.delegate(.completed)):
			return .send(.delegate(.completed))

		case .createAccount(.delegate(.accountCreated)):
			appEventsClient.handleEvent(.walletCreated)
			return .run { _ in
				_ = await radixConnectClient.loadP2PLinksAndConnectAll()
			}

		default:
			return .none
		}
	}
}
