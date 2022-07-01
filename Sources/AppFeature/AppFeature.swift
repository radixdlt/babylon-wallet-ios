import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature
import SwiftUI

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	// MARK: State
	struct State: Equatable {
		public var main: Main.State?
		public var onboarding: Onboarding.State?
		public var splash: Splash.State?

		public init(
			splash: Splash.State? = .init(),
			main: Main.State? = nil,
			onboarding: Onboarding.State? = nil
		) {
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
	}
}

public extension App {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

public extension App {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>

	static let reducer = Reducer.combine(
		Main.reducer
			.optional()
			.pullback(
				state: \.main,
				action: /Action.main,
				environment: { _ in
					Main.Environment()
				}
			),

		Onboarding.reducer
			.optional()
			.pullback(
				state: \.onboarding,
				action: /Action.onboarding,
				environment: { _ in
					Onboarding.Environment()
				}
			),

		Splash.reducer
			.optional()
			.pullback(
				state: \.splash,
				action: /Action.splash,
				environment: { _ in
					Splash.Environment()
				}
			),

		appReducer
	)

	static let appReducer = Reducer { _, action, _ in
		switch action {
		case .main: break
		case .onboarding: break
		case .splash: break
		}
		return .none
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
	}
}

// MARK: - AppCoordinator_Previews
struct AppCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		App.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: App.reducer,
				environment: .init()
			)
		)
	}
}
