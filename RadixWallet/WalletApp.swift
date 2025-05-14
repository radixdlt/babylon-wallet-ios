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
							.dependency(\.userDefaults, .radix)

						#if targetEnvironment(simulator)
							.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }
						#endif
					}
				)
			} else {
				Text("Running tests")
			}
		}
	}
}
