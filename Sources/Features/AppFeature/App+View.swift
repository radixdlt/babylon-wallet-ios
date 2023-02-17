import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: - App.View
extension App {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension App.View {
	public var body: some View {
		ZStack {
			SwitchStore(store.scope(state: \.root)) {
				CaseLet(
					state: /App.State.Root.main,
					action: { App.Action.child(.main($0)) },
					then: { Main.View(store: $0) }
				)

				CaseLet(
					state: /App.State.Root.onboardingCoordinator,
					action: { App.Action.child(.onboardingCoordinator($0)) },
					then: { OnboardingCoordinator.View(store: $0) }
				)

				CaseLet(
					state: /App.State.Root.splash,
					action: { App.Action.child(.splash($0)) },
					then: { Splash.View(store: $0) }
				)
			}
			.alert(
				store: store.scope(
					state: \.$alert,
					action: { .view(.alert($0)) }
				),
				state: /App.Alerts.State.userErrorAlert,
				action: App.Alerts.Action.userErrorAlert
			)
			.alert(
				store: store.scope(
					state: \.$alert,
					action: { .view(.alert($0)) }
				),
				state: /App.Alerts.State.incompatibleProfileErrorAlert,
				action: App.Alerts.Action.incompatibleProfileErrorAlert
			)
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
			.showDeveloperDisclaimerBanner()
			.presentsLoadingViewOverlay()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(
				initialState: .init(),
				reducer: App()
					.dependency(\.localAuthenticationClient.queryConfig) {
						.biometricsAndPasscodeSetUp
					}
					.dependency(\.profileClient.loadProfile) {
						.failure(.profileVersionOutdated(json: Data(), version: .zero))
					}
			)
		)
	}
}

#endif
