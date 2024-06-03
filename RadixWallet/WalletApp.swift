import ComposableArchitecture
import SwiftUI

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	@UIApplicationDelegateAdaptor var delegate: AppDelegate

	init() {
		#if DEBUG
		// MUST NOT be called twice (panics...)
		// MUST NOT be enabled in PROD (not ensured that secrets are omitted)
		// This is VERY VERY verbose, so mosly useful for debugging.
		enableLoggingFromRust()
		#endif
	}

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
				.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
			} else {
				Text("Running tests")
			}
		}
	}
}
