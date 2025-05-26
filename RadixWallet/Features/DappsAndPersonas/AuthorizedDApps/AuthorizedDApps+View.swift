import ComposableArchitecture
import SwiftUI

extension AuthorizedDappsFeature.State {
	var dAppsDetails: IdentifiedArrayOf<DAppsListView.DApp> {
		dApps.map {
			DAppsListView.DApp(
				id: $0.id,
				name: $0.displayName ?? L10n.DAppRequest.Metadata.unknownName,
				thumbnail: thumbnails[$0.id],
				description: nil,
				hasClaim: dappsWithClaims.contains($0.id)
			)
		}
		.asIdentified()
	}
}

// MARK: - AuthorizedDappsFeature.View
extension AuthorizedDappsFeature {
	@MainActor
	struct View: SwiftUI.View {
		private let store: Store

		init(store: Store) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .medium1) {
						Text(L10n.AuthorizedDapps.subtitle)
							.textBlock

						InfoButton(.dapps, label: L10n.InfoLink.Title.dapps)

						DAppsListView(dApps: viewStore.dAppsDetails) { id in
							viewStore.send(.view(.didSelectDapp(id)))
						}
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.secondaryBackground)
				.radixToolbar(title: L10n.AuthorizedDapps.title)
				.destinations(with: store)
				.task {
					viewStore.send(.view(.task))
				}
			}
		}
	}
}

// MARK: - Extensions

private extension StoreOf<AuthorizedDappsFeature> {
	var destination: PresentationStoreOf<AuthorizedDappsFeature.Destination> {
		func scopeState(state: State) -> PresentationState<AuthorizedDappsFeature.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AuthorizedDappsFeature>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(store: destinationStore.scope(state: \.presentedDapp, action: \.presentedDapp)) {
			DappDetails.View(store: $0)
		}
	}
}
