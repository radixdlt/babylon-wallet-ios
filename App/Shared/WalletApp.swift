import AppFeature
import ComposableArchitecture
import DesignSystem
import KeychainClientDependency
import ProfileClient
import SwiftUI
import UserDefaultsClient

typealias App = AppFeature.App

public extension App.Environment {
	static let live: Self = .init(
		mainQueue: .main,
		appSettingsClient: .liveValue,
		accountPortfolioFetcher: .liveValue,
		keychainClient: .liveValue,
		pasteboardClient: .liveValue,
		profileLoader: .liveValue,
		userDefaultsClient: .liveValue,
		profileClient: .liveValue
	)
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

	var body: some SwiftUI.Scene {
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
