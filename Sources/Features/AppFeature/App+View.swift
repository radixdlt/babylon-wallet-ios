import ComposableArchitecture
import MainFeature
import OnboardingFeature
import SplashFeature
import SwiftUI

// MARK: - App.View
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
		SwitchStore(store.scope(state: \.root)) {
			CaseLet(
				state: /App.State.Root.main,
				action: { App.Action.child(.main($0)) },
				then: Main.View.init(store:)
			)

			CaseLet(
				state: /App.State.Root.onboarding,
				action: { App.Action.child(.onboarding($0)) },
				then: Onboarding.View.init(store:)
			)

			CaseLet(
				state: /App.State.Root.splash,
				action: { App.Action.child(.splash($0)) },
				then: Splash.View.init(store:)
			)
		}
	}
}

#if DEBUG

// MARK: - AppView_Previews
struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(
				initialState: .init(),
				reducer: App()
			)
		)
	}
}

#endif // DEBUG
