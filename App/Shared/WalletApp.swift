import AppFeature
import ComposableArchitecture
import SwiftUI
import XCTestDynamicOverlay

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	var body: some SwiftUI.Scene {
		WindowGroup {
			// Disable starting app when running tests, see TCA discussion:
			// https://github.com/pointfreeco/swift-composable-architecture/discussions/1652#discussioncomment-4112291
			if !_XCTIsTesting {
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
}
