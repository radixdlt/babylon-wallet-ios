import ComposableArchitecture
import SwiftUI

public func fixme(line: UInt = #line, file: StaticString = #file) -> Never {
	fatalError("Fix me: \(file)\(line)")
}

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
				.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
			} else {
				Text("Running tests")
			}
		}
	}
}
