import AppFeature
import ComposableArchitecture
import DesignSystem
import KeychainClient
import SwiftUI
import UserDefaultsClient
import WalletClient

typealias App = AppFeature.App

public extension App.Environment {
	static let live: Self = {
		let keychainClient: KeychainClient = .live()

		return Self(
			backgroundQueue: DispatchQueue(label: "background-queue").eraseToAnyScheduler(),
			mainQueue: .main,
			appSettingsClient: .live(),
			accountPortfolioFetcher: .live(),
			keychainClient: keychainClient,
			pasteboardClient: .live(),
			profileLoader: .live(keychainClient: keychainClient),
			userDefaultsClient: .live(),
			walletClient: .live
		)
	}()
}

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	let store: Store

	init() {
		store = Store(
			initialState: .init(),
			reducer: App.reducer,
			environment: .live
		)

		DesignSystem.registerFonts()
	}

	var body: some Scene {
		WindowGroup {
			App.View(store: store)

			#if os(macOS)
				.frame(minWidth: 1020, maxWidth: .infinity, minHeight: 512, maxHeight: .infinity)
			#endif

			// FIXME: Move to Settings
			// Text("Version: \(Bundle.main.appVersionLong) build #\(Bundle.main.appBuild)")
		}
	}
}

// MARK: WalletApp.Store
extension WalletApp {
	typealias Store = ComposableArchitecture.Store<App.State, App.Action>
}
