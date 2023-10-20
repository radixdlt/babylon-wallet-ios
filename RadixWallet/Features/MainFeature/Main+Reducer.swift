import ComposableArchitecture
import SwiftUI
public struct Main: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var home: Home.State

		public var isOnMainnet = true

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(home: Home.State) {
			self.home = home
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removedWallet
	}

	public enum InternalAction: Sendable, Equatable {
		case currentGatewayChanged(to: Radix.Gateway)
		case profileOwnershipConflict(OwnershipConflict)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case settings(Settings.State)
		}

		public enum Action: Sendable, Equatable {
			case settings(Settings.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.settings, action: /Action.settings) {
				Settings()
			}
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.home, action: /Action.child .. ChildAction.home) {
			Home()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				for try await gateway in await gatewaysClient.currentGatewayValues() {
					guard !Task.isCancelled else { return }
					loggerGlobal.notice("Changed network to: \(gateway)")
					await send(.internal(.currentGatewayChanged(to: gateway)))
				}
			}
			.merge(
				with: .run { send in
					for try await deviceConflict in await onboardingClient.conflictingDeviceUsages() {
						guard !Task.isCancelled else { return }
						loggerGlobal.notice("Profile device ownership conflict: \(deviceConflict)")
						await send(.internal(.profileOwnershipConflict(deviceConflict)))
					}
				}
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		case let .destination(.presented(.settings(.delegate(.deleteProfileAndFactorSources(keepInIcloudIfPresent))))):
			return .run { send in
				try await appPreferencesClient.deleteProfileAndFactorSources(keepInIcloudIfPresent)
				await send(.delegate(.removedWallet))
			} catch: { error, _ in
				loggerGlobal.error("Failed to delete profile: \(error)")
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .currentGatewayChanged(currentGateway):
			state.isOnMainnet = currentGateway.network == .mainnet
			return .none
		case let .profileOwnershipConflict(ownershipConflict):
			loggerGlobal.warning("NOT DOING ANYTHING WITH OWNERSHIP CONFLICT")
			return .none
		}
	}
}
