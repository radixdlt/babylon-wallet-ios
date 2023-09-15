import AppFeature
import FeaturePrelude
import SwiftUI

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	@UIApplicationDelegateAdaptor var delegate: AppDelegate

	var body: some SwiftUI.Scene {
		WindowGroup {
			App.View(
				store: Store(
					initialState: App.State(
						buildConfiguration: {
							#if BETA
							return "BETA"
							#elseif ALPHA
							return "ALPHA"
							#elseif DEV
							return "DEV"
							#elseif PREALPHA
							return "PREALPHA"
							#elseif RELEASE
							return "RELEASE"
							#endif
						}()
					)
				) {
					App()
					#if targetEnvironment(simulator)
						.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }
					#endif
				}
			)
			#if os(macOS)
			.frame(minWidth: 1020, maxWidth: .infinity, minHeight: 512, maxHeight: .infinity)
			#endif
			.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
		}
	}
}
