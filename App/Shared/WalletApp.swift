import AppFeature
import ComposableArchitecture
import DesignSystem
import KeychainClientDependency
import ProfileClient
import SwiftUI
import UserDefaultsClient

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	init() {
		DesignSystem.registerFonts()
	}

	var body: some SwiftUI.Scene {
		WindowGroup {
			App.View(
				store: Store(
					initialState: App.State(),
					reducer: App()
				)
			)
			#if os(macOS)
			.frame(minWidth: 1020, maxWidth: .infinity, minHeight: 512, maxHeight: .infinity)
			#endif
			.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
		}
	}
}
