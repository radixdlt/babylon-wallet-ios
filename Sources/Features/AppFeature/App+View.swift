import AssetTransferFeature
import CreateAccountFeature
import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

// MARK: - App.View
extension App {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<App>

		public init(store: StoreOf<App>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ZStack {
					SwitchStore(store.scope(state: \.root, action: Action.child)) { state in
						switch state {
						case .main:
							CaseLet(
								state: /App.State.Root.main,
								action: App.ChildAction.main,
								then: { Main.View(store: $0) }
							)

						case .onboardingCoordinator:
							CaseLet(
								state: /App.State.Root.onboardingCoordinator,
								action: App.ChildAction.onboardingCoordinator,
								then: { OnboardingCoordinator.View(store: $0) }
							)

						case .splash:
							CaseLet(
								state: /App.State.Root.splash,
								action: App.ChildAction.splash,
								then: { Splash.View(store: $0) }
							)
						case .onboardTestnetUserToMainnet:
							CaseLet(
								state: /App.State.Root.onboardTestnetUserToMainnet,
								action: App.ChildAction.onboardTestnetUserToMainnet,
								then: { CreateAccountCoordinator.View(store: $0) }
							)
						}
					}
					.tint(.app.gray1)
					.alert(
						store: store.scope(state: \.$alert, action: { .view(.alert($0)) }),
						state: /App.Alerts.State.incompatibleProfileErrorAlert,
						action: App.Alerts.Action.incompatibleProfileErrorAlert
					)
					.task { @MainActor in
						await ViewStore(store.stateless).send(.view(.task)).finish()
					}
					.showDeveloperDisclaimerBanner(showIsUsingTestnetBanner: viewStore.showIsUsingTestnetBanner)
					.presentsLoadingViewOverlay()
				}
			}
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
			)
		)
	}
}
#endif
