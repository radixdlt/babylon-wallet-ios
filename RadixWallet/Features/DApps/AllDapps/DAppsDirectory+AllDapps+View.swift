import SwiftUI

// MARK: - DAppsDirectory.AllDapps.View
extension DAppsDirectory.AllDapps {
	struct View: SwiftUI.View {
		let store: StoreOf<DAppsDirectory.AllDapps>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					headerView()
					Separator()
					dAppsView()
				}
				.background(.primaryBackground)
				.destinations(with: store)
				.task { @MainActor in
					await store.send(.view(.task)).finish()
				}
			}
		}

		@ViewBuilder
		func headerView() -> some SwiftUI.View {
			DAppsFiltering.View(store: store.scope(state: \.filtering, action: \.child.filtering))
				.padding(.top, .small3)
				.padding(.bottom, .small1)
				.background(.primaryBackground)
		}

		@ViewBuilder
		func dAppsView() -> some SwiftUI.View {
			if store.isOnMainnet {
				ScrollView {
					VStack(spacing: .medium1) {
						loadable(
							store.displayedDApps,
							loadingView: DAppsDirectory.loadingView,
							errorView: DAppsDirectory.failedView,
							successContent: loadedView
						)
					}
					.padding(.horizontal, .medium3)
					.padding(.vertical, .medium1)
					.frame(maxWidth: .infinity)
				}
				.background(.secondaryBackground)
				.refreshable {
					store.send(.view(.pullToRefreshStarted))
				}
			} else {
				VStack {
					Spacer()
					Text("No available dApps on this network.")
						.textBlock
						.multilineTextAlignment(.center)
					Spacer()
				}
				.padding(.horizontal, .large2)
				.frame(maxWidth: .infinity, alignment: .center)
				.background(.secondaryBackground)
			}
		}

		@ViewBuilder
		func loadedView(dAppsCategories: DAppsDirectory.DAppsCategories) -> some SwiftUI.View {
			DAppsDirectory.loadedView(dAppsCategories: dAppsCategories) { dApp in
				store.send(.view(.didSelectDapp(dApp.id)))
			}
		}
	}
}

private extension StoreOf<DAppsDirectory.AllDapps> {
	var destination: PresentationStoreOf<DAppsDirectory.AllDapps.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DAppsDirectory.AllDapps>) -> some View {
		let destinationStore = store.destination
		return
			navigationDestination(store: destinationStore.scope(state: \.presentedDapp, action: \.presentedDapp)) {
				DappDetails.View(store: $0)
			}
	}
}
