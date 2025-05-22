import ComposableArchitecture
import SwiftUI

extension Main.State {
	var showIsUsingTestnetBanner: Bool {
		!isOnMainnet
	}
}

// MARK: - Main.View
extension Main {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Main>

		init(store: StoreOf<Main>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			TabView {
				Group {
					NavigationStack {
						Home.View(store: store.home)
					}
					.tabItem {
						Label("Home", systemImage: "house")
					}

					NavigationStack {
						DAppsDirectory.View(store: store.dAppsDirectory)
					}
					.tabItem {
						Label("DApps", image: .authorizedDapps)
					}

					NavigationStack {
						Settings.View(store: store.settings)
					}
					.tabItem {
						Label("Settings", systemImage: "gearshape")
					}
				}
				.toolbarBackground(.visible, for: .tabBar)
				.toolbarBackground(Color.secondaryBackground, for: .tabBar)
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
			.showDeveloperDisclaimerBanner(store.banner)
			.presentsDappInteractions()
		}
	}
}

private extension StoreOf<Main> {
	var banner: Store<Bool, Never> {
		scope(state: \.showIsUsingTestnetBanner, action: actionless)
	}

	var home: StoreOf<Home> {
		scope(state: \.home, action: \.child.home)
	}

	var settings: StoreOf<Settings> {
		scope(state: \.settings, action: \.child.settings)
	}

	var dAppsDirectory: StoreOf<DAppsDirectory> {
		scope(state: \.dAppsDirectory, action: \.child.dAppsDirectory)
	}
}
