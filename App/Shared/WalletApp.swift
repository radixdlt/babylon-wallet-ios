import AppFeature
import ComposableArchitecture
import DesignSystem
import KeychainClient
import ProfileClient
import SwiftUI
import UserDefaultsClient

typealias App = AppFeature.App

public extension App.Environment {
	static let live: Self = {
		let keychainClient = KeychainClient.live

		let backgroundQueue = DispatchQueue(label: "background-queue").eraseToAnyScheduler()

		return Self(
			backgroundQueue: backgroundQueue,
			mainQueue: .main,
			appSettingsClient: .liveValue,
			accountPortfolioFetcher: .liveValue,
			keychainClient: keychainClient,
			pasteboardClient: .live(),
			profileLoader: .live(keychainClient: keychainClient),
			userDefaultsClient: .liveValue,
			profileClient: .live(backgroundQueue: backgroundQueue)
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
				.environment(\.colorScheme, .light) // TODO: implement dark mode and remove this
		}
	}
}

// MARK: WalletApp.Store
extension WalletApp {
	typealias Store = ComposableArchitecture.Store<App.State, App.Action>
}
