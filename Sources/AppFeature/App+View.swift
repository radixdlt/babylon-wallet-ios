import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature
import SwiftUI

public extension App {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension App.View {
	var body: some View {
		SwitchStore(store) {
			CaseLet(
				state: /App.State.main,
				action: App.Action.main,
				then: Main.View.init(store:)
			)

			CaseLet(
				state: /App.State.onboarding,
				action: App.Action.onboarding,
				then: Onboarding.View.init(store:)
			)

			CaseLet(
				state: /App.State.splash,
				action: App.Action.splash,
				then: Splash.View.init(store:)
			)
		}
	}
}

// MARK: - AppView_Previews
struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(
				initialState: .init(),
				reducer: App.reducer,
				environment: .noop
			)
		)
	}
}
