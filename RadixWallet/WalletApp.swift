import ComposableArchitecture
import SwiftUI

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	@UIApplicationDelegateAdaptor var delegate: AppDelegate

	#if DEBUG // to test our Slack integration, this will work with DEBUG but fail when archiving...
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
				.task {
					GatewayAPIClient.rdxClientVersion = rdxClientVersion
				}
				.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
			} else {
				Text("Running tests")
			}
		}
	}
	#endif
}

extension WalletApp {
	private var rdxClientVersion: String? {
		let buildConfiguration: String = {
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
			#else
			return "UNKNOWN"
			#endif
		}()

		guard
			let mainBundleInfoDictionary = Bundle.main.infoDictionary,
			let version = mainBundleInfoDictionary["CFBundleShortVersionString"] as? String,
			let buildNumber = mainBundleInfoDictionary["CFBundleVersion"] as? String
		else {
			return nil
		}

		return version
			+ "#" + buildNumber
			+ "-" + buildConfiguration
	}
}
