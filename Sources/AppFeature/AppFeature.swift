import ComposableArchitecture
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import SwiftUI
import UserDefaultsClient
import Wallet
import WalletLoader

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	// MARK: State
	struct State: Equatable {
		// Remove alert from App later on, just used in early stage for presenting errors
		public var alert: AlertState<Action>?

		public var main: Main.State?
		public var onboarding: Onboarding.State?
		public var splash: Splash.State?

		public init(
			alert: AlertState<Action>? = nil,
			splash: Splash.State? = .init(),
			main: Main.State? = nil,
			onboarding: Onboarding.State? = nil
		) {
			self.alert = alert
			self.splash = splash
			self.main = main
			self.onboarding = onboarding
		}
	}
}

public extension App {
	// MARK: Action
	enum Action: Equatable {
		case main(Main.Action)
		case onboarding(Onboarding.Action)
		case splash(Splash.Action)

		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

public extension App.Action {
	enum CoordinatingAction: Equatable {
		case onboard
		case toMain(Wallet)
	}
}

public extension App.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension App.Action.InternalAction {
	enum UserAction: Equatable {
		case alertDismissed
	}
}

public extension App {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let profileLoader: ProfileLoader
		public let userDefaultsClient: UserDefaultsClient
		public let walletLoader: WalletLoader
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			walletLoader: WalletLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.walletLoader = walletLoader
		}
	}
}

#if DEBUG
public extension App.Environment {
	static let noop = Self(
		backgroundQueue: .immediate,
		mainQueue: .immediate,
		profileLoader: .noop,
		userDefaultsClient: .noop,
		walletLoader: .noop
	)
}
#endif // DEBUG

public extension App {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	static let reducer = Reducer.combine(
		Main.reducer
			.optional()
			.pullback(
				state: \.main,
				action: /Action.main,
				environment: {
					Main.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						userDefaultsClient: $0.userDefaultsClient
					)
				}
			),

		Onboarding.reducer
			.optional()
			.pullback(
				state: \.onboarding,
				action: /Action.onboarding,
				environment: {
					Onboarding.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						userDefaultsClient: $0.userDefaultsClient
					)
				}
			),

		Splash.reducer
			.optional()
			.pullback(
				state: \.splash,
				action: /Action.splash,
				environment: {
					Splash.Environment(
						backgroundQueue: $0.backgroundQueue,
						mainQueue: $0.mainQueue,
						profileLoader: $0.profileLoader,
						walletLoader: $0.walletLoader
					)
				}
			),

		appReducer
	)
	.debug()

	static let appReducer = Reducer { state, action, _ in
		switch action {
		case .main(.coordinate(.removedWallet)):
			state.main = nil
			return Effect(value: .coordinate(.onboard))

		case .main:
			return .none
		case let .onboarding(.coordinate(.onboardedWithWallet(wallet))):
			state.onboarding = nil
			return Effect(value: .coordinate(.toMain(wallet)))
		case .onboarding:
			return .none

		case let .splash(.coordinate(.loadWalletResult(loadWalletResult))):

			state.splash = nil
			switch loadWalletResult {
			case let .walletLoaded(wallet):
				return Effect(value: .coordinate(.toMain(wallet)))
			case let .noWallet(.noProfileFoundAtPath(path)):
				state.alert = .init(
					title: TextState("No profile found at: \(path)"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			case .noWallet(.failedToLoadProfileFromDocument):
				state.alert = .init(
					title: TextState("Failed to load profile from document"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			case .noWallet(.secretsNotFoundForProfile):
				state.alert = .init(
					title: TextState("Secrets not found for profile"),
					buttons: [
						.cancel(
							TextState("OK, I'll onboard"),
							action: .send(.coordinate(.onboard))
						),
					]
				)
				return .none
			}

		case .splash:
			return .none

		case .coordinate(.onboard):
			state.onboarding = .init()
			return .none
		case let .coordinate(.toMain(wallet)):
			state.main = .init(wallet: wallet)
			return .none
		case .internal(.user(.alertDismissed)):
			state.alert = nil
			return .none
		}
	}
}

public extension App {
	// MARK: Coordinator
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>

		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension App.Coordinator {
	// MARK: Body
	var body: some View {
		ZStack {
			Text("<APP EMPTY STATE>") // Handle better, make App.State an enum?
				.foregroundColor(Color.red)
				.background(Color.yellow)
				.font(.largeTitle)
				.zIndex(0)

			IfLetStore(
				store.scope(state: \.main, action: App.Action.main),
				then: Main.Coordinator.init(store:)
			)
			.zIndex(1)

			IfLetStore(
				store.scope(state: \.onboarding, action: App.Action.onboarding),
				then: Onboarding.Coordinator.init(store:)
			)
			.zIndex(2)

			IfLetStore(
				store.scope(state: \.splash, action: App.Action.splash),
				then: Splash.Coordinator.init(store:)
			)
			.zIndex(3)
		}
		.alert(store.scope(state: \.alert), dismiss: .internal(.user(.alertDismissed)))
	}
}

// MARK: - AppCoordinator_Previews
#if DEBUG
struct AppCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		App.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: App.reducer,
				environment: .noop
			)
		)
	}
}

#endif // DEBUG
