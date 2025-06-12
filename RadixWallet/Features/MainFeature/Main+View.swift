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
			WithViewStore(store, observe: { $0 }) { viewStore in
				NavigationStack {
					TabView {
						tabs(isOnMainnet: viewStore.isOnMainnet)
					}
				}
			}
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
			.showDeveloperDisclaimerBanner(store.banner)
			.presentsDappInteractions()
		}

		func tabs(isOnMainnet: Bool) -> some SwiftUI.View {
			Group {
				walletTab
				if isOnMainnet {
					dAppDirectoryTab
				}
				discoverTab
				settingsTab
			}
			.toolbarBackground(.visible, for: .tabBar)
			.toolbarBackground(Color.secondaryBackground, for: .tabBar)
		}

		var walletTab: some SwiftUI.View {
			NavigationStack {
				Home.View(store: store.home)
			}
			.tabItem {
				Label(L10n.HomePage.Tab.wallet, image: .radixIcon)
			}
		}

		var dAppDirectoryTab: some SwiftUI.View {
			NavigationStack {
				DAppsDirectory.View(store: store.dAppDirectory)
			}
			.tabItem {
				Label(L10n.HomePage.Tab.dapps, image: .authorizedDapps)
			}
		}

		var settingsTab: some SwiftUI.View {
			NavigationStack {
				Settings.View(store: store.settings)
			}
			.tabItem {
				Label(L10n.HomePage.Tab.settings, image: .settings)
			}
		}

		var discoverTab: some SwiftUI.View {
			NavigationStack {
				Discover.View(store: store.discover)
			}
			.tabItem {
				Label("Discover", systemImage: "safari")
			}
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

	var dAppDirectory: StoreOf<DAppsDirectory> {
		scope(state: \.dAppsDirectory, action: \.child.dAppsDirectory)
	}

	var discover: StoreOf<Discover> {
		scope(state: \.discover, action: \.child.discover)
	}
}
