import AppFeature
import FeaturePrelude

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	var body: some SwiftUI.Scene {
		WindowGroup {
			App.View(
				store: Store(
					initialState: App.State(),
					reducer: App()
					#if targetEnvironment(simulator)
						.dependency(\.localAuthenticationClient.queryConfig) { .biometricsAndPasscodeSetUp }
					#endif
				)
			)
			#if os(macOS)
			.frame(minWidth: 1020, maxWidth: .infinity, minHeight: 512, maxHeight: .infinity)
			#endif
			.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
		}
	}
}
