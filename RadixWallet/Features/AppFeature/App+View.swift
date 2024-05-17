import ComposableArchitecture
import SwiftUI

extension View {
	@MainActor
	func configureNavigationBarAppearence() {
		func setUp(appearence: UINavigationBarAppearance) {
			appearence.titleTextAttributes = [.foregroundColor: UIColor(Color.app.gray1), .font: UIFont(font: FontFamily.IBMPlexSans.semiBold, size: 16)!]
			appearence.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.app.gray1)]
			let image = UIImage(named: "arrow-back")
			appearence.setBackIndicatorImage(image, transitionMaskImage: image)
			appearence.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
		}

		let scrollEdgeAppearence = UINavigationBarAppearance()
		scrollEdgeAppearence.configureWithTransparentBackground()
		setUp(appearence: scrollEdgeAppearence)
		UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearence

		let standardAppearence = UINavigationBarAppearance()
		standardAppearence.configureWithOpaqueBackground()
		standardAppearence.backgroundColor = UIColor(Color.app.background)
		setUp(appearence: standardAppearence)
		UINavigationBar.appearance().standardAppearance = standardAppearence
	}
}

// MARK: - App.View
extension App {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<App>

		public init(store: StoreOf<App>) {
			self.store = store
			configureNavigationBarAppearence()
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
