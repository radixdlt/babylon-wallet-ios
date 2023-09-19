import AssetTransferFeature
import CreateAccountFeature
import FeaturePrelude
import MainFeature
import OnboardingFeature
import SplashFeature

extension App.State {
	var viewState: App.ViewState {
		.init(
			showIsUsingTestnetBanner: {
				guard hasMainnetEverBeenLive else {
					return false
				}
				if isCurrentlyOnboardingUser {
					return false
				}

				return !isOnMainnet
			}()
		)
	}
}

// MARK: - App.View
extension App {
	public struct ViewState: Equatable {
		let showIsUsingTestnetBanner: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<App>

		public init(store: StoreOf<App>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(spacing: 0) {
				conditionalBannerView
				appView
			}
		}

		private var conditionalBannerView: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				if viewStore.showIsUsingTestnetBanner {
					DeveloperDisclaimerBanner()
				}
			}
		}

		private var appView: some SwiftUI.View {
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
				case .onboardTestnetUserToMainnet:
					CaseLet(
						/App.State.Root.onboardTestnetUserToMainnet,
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
				await store.send(.view(.task)).finish()
			}
			.presentsLoadingViewOverlay()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

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
