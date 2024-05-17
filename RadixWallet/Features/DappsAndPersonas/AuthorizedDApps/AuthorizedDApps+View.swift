import ComposableArchitecture
import SwiftUI

// MARK: - AuthorizedDapps.View
extension AuthorizedDappsFeature {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	public struct ViewState: Equatable {
		let dApps: IdentifiedArrayOf<Dapp>

		struct Dapp: Equatable, Identifiable {
			let id: AuthorizedDapp.ID
			let name: String
			let thumbnail: URL?
		}
	}
}

// MARK: - Body

extension AuthorizedDappsFeature.View {
	public var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					Text(L10n.AuthorizedDapps.subtitle)
						.textBlock
						.padding(.vertical, .medium3)

					Separator()
						.padding(.vertical, .medium3)

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							Card {
								viewStore.send(.didSelectDapp(dApp.id))
							} contents: {
								PlainListRow(title: dApp.name) {
									Thumbnail(.dapp, url: dApp.thumbnail)
								}
							}
						}
					}
					.animation(.easeInOut, value: viewStore.dApps)

					Spacer(minLength: 0)
				}
				.padding(.horizontal, .medium3)
				.onAppear {
					viewStore.send(.appeared)
				}
			}
			.setUpNavigationBar(title: L10n.AuthorizedDapps.title)
			.destinations(with: store)
		}
	}
}

// MARK: - Extensions

extension AuthorizedDappsFeature.State {
	var viewState: AuthorizedDappsFeature.ViewState {
		let dAppViewStates = dApps.map {
			AuthorizedDappsFeature.ViewState.Dapp(
				id: $0.id,
				name: $0.displayName ?? L10n.DAppRequest.Metadata.unknownName,
				thumbnail: thumbnails[$0.id]
			)
		}

		return .init(dApps: dAppViewStates.asIdentified())
	}
}

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
		return navigationDestination(
			store: destinationStore,
			state: /AuthorizedDappsFeature.Destination.State.presentedDapp,
			action: AuthorizedDappsFeature.Destination.Action.presentedDapp,
			destination: { DappDetails.View(store: $0) }
		)
	}
}
