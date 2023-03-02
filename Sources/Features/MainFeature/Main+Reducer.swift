import AppPreferencesClient
import FeaturePrelude
import HomeFeature
import SettingsFeature

public struct Main: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		// MARK: - Components
		public var home: Home.State

		// MARK: - Destinations
		@PresentationState
		public var destination: Destinations.State?

		public init(home: Home.State = .init()) {
			self.home = home
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case dappInteractionPresented
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case destination(PresentationActionOf<Destinations>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case removedWallet
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case settings(AppSettings.State)
		}

		public enum Action: Sendable, Equatable {
			case settings(AppSettings.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.settings, action: /Action.settings) {
				AppSettings()
			}
		}
	}

	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.home, action: /Action.child .. ChildAction.home) {
			Home()
		}

		Reduce(core)
			.presentationDestination(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .dappInteractionPresented:
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		case .destination(.presented(.settings(.delegate(.deleteProfileAndFactorSources)))):
			return .run { send in
				try await appPreferencesClient.deleteProfileAndFactorSources()
				await send(.delegate(.removedWallet))
			}

		// this should go away via network stream observation in the reducer (with .task)
		case .destination(.presented(.settings(.child(.destination(.presented(.manageGatewayAPIEndpoints(.delegate(.networkChanged)))))))):
			state.destination = nil
			state.home = .init()
			return .send(.child(.home(.view(.pullToRefreshStarted))))

		case .destination(.presented(.settings(.delegate(.dismiss)))):
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
