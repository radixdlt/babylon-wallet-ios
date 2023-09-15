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
					initialState: App.State()
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
			.task {
				// maybe we can inject it with regular .dependency()?
				#if BETA
				GatewayAPIClient.configuration = "BETA"
				#elseif ALPHA
				GatewayAPIClient.configuration = "ALPHA"
				#elseif DEV
				GatewayAPIClient.configuration = "DEV"
				#elseif PREALPHA
				GatewayAPIClient.configuration = "PREALPHA"
				#elseif RELEASE
				GatewayAPIClient.configuration = "RELEASE"
				#endif
			}
		}
	}
}

import GatewayAPI
