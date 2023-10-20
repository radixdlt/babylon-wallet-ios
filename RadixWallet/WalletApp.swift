import ComposableArchitecture
import SwiftUI

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	@UIApplicationDelegateAdaptor var delegate: AppDelegate

	var body: some SwiftUI.Scene {
		WindowGroup {
			if !_XCTIsTesting {
				App.View(
					store: Store(
						initialState: App.State()
					) {
						App()
						#if targetEnvironment(simulator)
							.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }
						#endif
					}
				)
				.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
			} else {
				Text("Running tests")
			}
		}
	}
}
