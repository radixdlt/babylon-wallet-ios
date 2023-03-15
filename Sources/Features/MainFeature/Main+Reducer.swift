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

		// MARK: - State
		public var canPresentDappInteraction: Bool = true

		public init(home: Home.State = .init()) {
			self.home = home
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case home(Home.Action)
		case destination(PresentationAction<Destinations.Action>)
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
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .home(.child(.destination(.presented(.createAccount(.delegate(.dismiss)))))),
		     .home(.child(.destination(.presented(.createAccount(.delegate(.completed)))))),
		     .home(.child(.destination(.presented(.accountDetails(.child(.destination(.presented(.preferences(.delegate(.dismiss)))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.manageFactorSources(.child(.destination(.presented(.importOlympiaFactorSource(.delegate(.dismiss)))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.manageFactorSources(.child(.destination(.presented(.importOlympiaFactorSource(.delegate(.imported)))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.manageP2PLinks(.child(.destination(.presented(.newConnection(.delegate(.dismiss)))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.manageP2PLinks(.child(.destination(.presented(.newConnection(.delegate(.newConnection)))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.authorizedDapps(.child(.presentedDapp(.presented(.view(.confirmDisconnectAlert(.presented(.cancelTapped))))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.authorizedDapps(.child(.presentedDapp(.presented(.view(.confirmDisconnectAlert(.presented(.confirmTapped))))))))))))),
		     .destination(.presented(.settings(.child(.destination(.presented(.authorizedDapps(.child(.presentedDapp(.presented(.child(.presentedPersona(.dismiss)))))))))))):
			state.canPresentDappInteraction = true
			return .none

		case .home(.child(.destination(.presented(.createAccount)))), // Create Account modal
		     .home(.child(.destination(.presented(.accountDetails(.child(.destination(.presented(.preferences(.view(.appeared)))))))))), // Account preferences modal
		     .destination(.presented(.settings(.child(.destination(.presented(.manageP2PLinks(.child(.destination(.presented(.newConnection)))))))))), // New P2PLink connection modal
		     .destination(.presented(.settings(.child(.destination(.presented(.authorizedDapps(.child(.presentedDapp(.presented(.view(.personaTapped))))))))))), // Persona details modal
		     .destination(.presented(.settings(.child(.destination(.presented(.authorizedDapps(.child(.presentedDapp(.presented(.view(.forgetThisDappTapped))))))))))), // Forget Dapp Alert
		     .destination(.presented(.settings(.child(.destination(.presented(.manageFactorSources(.child(.destination(.presented(.importOlympiaFactorSource)))))))))): // Import Olympia Factor Source modal
			state.canPresentDappInteraction = false
			return .none

		case .home(.delegate(.displaySettings)):
			state.destination = .settings(.init())
			return .none

		case .destination(.presented(.settings(.delegate(.deleteProfileAndFactorSources)))):
			return .run { send in
				try await appPreferencesClient.deleteProfileAndFactorSources()
				await send(.delegate(.removedWallet))
			}

		// this should go away via network stream observation in the reducer (with .task)
		case .destination(.presented(.settings(.child(.destination(.presented(.gatewaySettings(.delegate(.networkChanged)))))))):
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
