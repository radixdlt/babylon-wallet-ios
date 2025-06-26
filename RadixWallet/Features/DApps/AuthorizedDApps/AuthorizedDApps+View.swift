import ComposableArchitecture
import SwiftUI

// MARK: - DAppsDirectory.AuthorizedDappsFeature.View
extension DAppsDirectory.AuthorizedDappsFeature {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		init(store: Store) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					DAppsFiltering.View(store: store.scope(state: \.filtering, action: \.child.filtering))
						.padding(.top, .small3)
						.padding(.bottom, .small1)
						.background(.primaryBackground)
						.disabled(!viewStore.hasAnyDApps)
					Separator()

					ScrollView {
						VStack(spacing: .medium1) {
							loadable(
								viewStore.displayedDapps,
								loadingView: DAppsDirectory.loadingView,
								errorView: DAppsDirectory.failedView,
								successContent: {
									loadedView(viewStore, categorizedDapps: $0)
								}
							)
						}
						.padding(.horizontal, .medium3)
						.padding(.vertical, .medium1)
						.frame(maxWidth: .infinity)
					}
					.scrollDisabled(!viewStore.hasAnyDApps)
					.background(.secondaryBackground)
					.refreshable {
						await viewStore.send(.pullToRefreshStarted).finish()
					}
				}
				.destinations(with: store)
				.task {
					viewStore.send(.task)
				}
			}
		}

		@ViewBuilder
		func loadedView(
			_ viewStore: ViewStore<DAppsDirectory.AuthorizedDappsFeature.State, DAppsDirectory.AuthorizedDappsFeature.ViewAction>,
			categorizedDapps: DAppsDirectory.DAppsCategories
		) -> some SwiftUI.View {
			if !viewStore.hasAnyDApps {
				VStack {
					Spacer()
					Text(L10n.AuthorizedDapps.subtitle)
						.textBlock
						.multilineTextAlignment(.center)
					InfoButton(.dapps, label: L10n.InfoLink.Title.dapps)
					Spacer()
				}
				.padding(.top, .huge1)
				.padding(.horizontal, .large2)
				.frame(maxWidth: .infinity)
			} else {
				DAppsDirectory.loadedView(dAppsCategories: categorizedDapps, dappsWithClaims: viewStore.dappsWithClaims) {
					viewStore.send(.didSelectDapp($0.id))
				}
			}
		}

		func dAppCard(
			_ viewStore: ViewStore<DAppsDirectory.AuthorizedDappsFeature.State, DAppsDirectory.AuthorizedDappsFeature.ViewAction>,
			dApp: DAppsDirectory.DApp
		) -> some SwiftUI.View {
			Card {
				viewStore.send(.didSelectDapp(dApp.id))
			} contents: {
				VStack(alignment: .leading, spacing: .zero) {
					PlainListRow(dApp: dApp)

					if viewStore.dappsWithClaims.contains(dApp.id) {
						StatusMessageView(text: L10n.AuthorizedDapps.pendingDeposit, type: .warning, useNarrowSpacing: true)
							.padding(.horizontal, .medium1)
							.padding(.bottom, .medium3)
					}

					DAppsDirectory.dAppTags(dApp)
				}
			}
		}
	}
}

// MARK: - Extensions

private extension StoreOf<DAppsDirectory.AuthorizedDappsFeature> {
	var destination: PresentationStoreOf<DAppsDirectory.AuthorizedDappsFeature.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DAppsDirectory.AuthorizedDappsFeature>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.presentedDapp, action: \.presentedDapp)) {
			DappDetails.View(store: $0)
		}
	}
}
