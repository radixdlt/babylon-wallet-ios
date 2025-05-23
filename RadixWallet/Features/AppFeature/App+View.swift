import ComposableArchitecture
import SwiftUI

// MARK: - App.View
extension App {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<App>

		init(store: StoreOf<App>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				SwitchStore(store.scope(state: \.root, action: \.child)) { state in
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
				.tint(.primaryText)
				.background(.primaryBackground)
				.presentsLoadingViewOverlay()
				.preferredColorScheme(viewStore.preferredTheme.colorScheme)
				.onOpenURL { url in
					store.send(.view(.urlOpened(url)))
				}
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}
	}
}

extension AppTheme {
	var colorScheme: ColorScheme? {
		switch self {
		case .light:
			.light
		case .dark:
			.dark
		case .system:
			nil
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
