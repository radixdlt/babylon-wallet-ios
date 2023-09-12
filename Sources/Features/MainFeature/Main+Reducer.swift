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

		public init(home: Home.State) {
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

	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.userDefaultsClient) var userDefaultsClient: UserDefaultsClient

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

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .home(.delegate(.displaySettings)):
			let showMigrateOlympiaButton = !userDefaultsClient.hideMigrateOlympiaButton
			state.destination = .settings(.init(showMigrateOlympiaButton: showMigrateOlympiaButton))
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
}
