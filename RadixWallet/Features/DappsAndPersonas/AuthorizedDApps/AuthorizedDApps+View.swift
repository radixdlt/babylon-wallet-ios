import ComposableArchitecture
import SwiftUI

extension AuthorizedDappsFeature.State {
	struct Dapp: Equatable, Identifiable {
		let id: AuthorizedDapp.ID
		let name: String
		let thumbnail: URL?
	}

	var dAppsDetails: IdentifiedArrayOf<Dapp> {
		dApps.map {
			Dapp(
				id: $0.id,
				name: $0.displayName ?? L10n.DAppRequest.Metadata.unknownName,
				thumbnail: thumbnails[$0.id]
			)
		}
		.asIdentified()
	}
}

// MARK: - AuthorizedDappsFeature.View
extension AuthorizedDappsFeature {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(alignment: .leading, spacing: .medium1) {
						Text(L10n.AuthorizedDapps.subtitle)
							.textBlock

						InfoButton(.dapps, label: L10n.AuthorizedDapps.whatIsDapp)

						VStack(spacing: .small1) {
							ForEach(viewStore.dAppsDetails) { dApp in
								Card {
									viewStore.send(.view(.didSelectDapp(dApp.id)))
								} contents: {
									PlainListRow(context: .dappAndPersona, title: dApp.name) {
										Thumbnail(.dapp, url: dApp.thumbnail)
									}
								}
							}
						}
						.animation(.easeInOut, value: viewStore.dApps)
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
					.onAppear {
						viewStore.send(.view(.appeared))
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.app.gray5)
				.radixToolbar(title: L10n.AuthorizedDapps.title)
				.destinations(with: store)
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
