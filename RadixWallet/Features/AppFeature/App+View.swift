import ComposableArchitecture
import SwiftUI

// MARK: - App.View
extension App {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<App>

		public init(store: StoreOf<App>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
				switch state {
				case .main:
					CaseLet(
						/App.State.Root.main,
						action: App.ChildAction.main,
						then: { Main.View(store: $0) }
					)

				case .onboardingCoordinator:
					CaseLet(
						/App.State.Root.onboardingCoordinator,
						action: App.ChildAction.onboardingCoordinator,
						then: { OnboardingCoordinator.View(store: $0) }
					)

				case .splash:
					CaseLet(
						/App.State.Root.splash,
						action: App.ChildAction.splash,
						then: { Splash.View(store: $0) }
					)
				}
			}
			.tint(.app.gray1)
			.alert(
				store: store.scope(state: \.$alert, action: { .view(.alert($0)) }),
				state: /App.Alerts.State.incompatibleProfileErrorAlert,
				action: App.Alerts.Action.incompatibleProfileErrorAlert
			)
			.presentsLoadingViewOverlay()
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(initialState: .init()) {
				App()
					.dependency(\.localAuthenticationClient.queryConfig) {
						.biometricsAndPasscodeSetUp
					}
			}
		)
	}
}
#endif
