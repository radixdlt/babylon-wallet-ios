import ComposableArchitecture
import SwiftUI

extension AuthorizedDappsFeature.State {
	struct Dapp: Equatable, Identifiable {
		let id: AuthorizedDapp.ID
		let name: String
		let thumbnail: URL?
		let hasClaim: Bool
	}

	var dAppsDetails: IdentifiedArrayOf<Dapp> {
		dApps.map {
			Dapp(
				id: $0.id,
				name: $0.displayName ?? L10n.DAppRequest.Metadata.unknownName,
				thumbnail: thumbnails[$0.id],
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

						VStack(spacing: .small1) {
							ForEach(viewStore.dAppsDetails) { dApp in
								Card {
									viewStore.send(.view(.didSelectDapp(dApp.id)))
								} contents: {
									VStack(alignment: .leading, spacing: .zero) {
										PlainListRow(context: .dappAndPersona, title: dApp.name) {
											Thumbnail(.dapp, url: dApp.thumbnail)
										}
										if dApp.hasClaim {
											StatusMessageView(text: L10n.AuthorizedDapps.pendingDeposit, type: .warning, useNarrowSpacing: true)
												.padding(.horizontal, .medium1)
												.padding(.bottom, .medium3)
										}
									}
								}
							}
						}
						.animation(.easeInOut, value: viewStore.dApps)
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(.app.gray5)
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
