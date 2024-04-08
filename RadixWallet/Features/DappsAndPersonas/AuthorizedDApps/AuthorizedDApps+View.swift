import ComposableArchitecture
import SwiftUI

// MARK: - AuthorizedDapps.View
extension AuthorizedDapps {
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
			let id: Profile.Network.AuthorizedDapp.ID
			let name: String
			let thumbnail: URL?
		}
	}
}

// MARK: - Body

extension AuthorizedDapps.View {
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
			.navigationTitle(L10n.AuthorizedDapps.title)
			.destinations(with: store)
		}
	}
}

// MARK: - Extensions

extension AuthorizedDapps.State {
	var viewState: AuthorizedDapps.ViewState {
		let dAppViewStates = dApps.map {
			AuthorizedDapps.ViewState.Dapp(
				id: $0.id,
				name: $0.displayName?.rawValue ?? L10n.DAppRequest.Metadata.unknownName,
				thumbnail: thumbnails[$0.id]
			)
		}

		return .init(dApps: dAppViewStates.asIdentifiable())
	}
}

private extension StoreOf<AuthorizedDapps> {
	var destination: PresentationStoreOf<AuthorizedDapps.Destination> {
		func scopeState(state: State) -> PresentationState<AuthorizedDapps.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AuthorizedDapps>) -> some View {
		let destinationStore = store.destination
		return navigationDestination(
			store: destinationStore,
			state: /AuthorizedDapps.Destination.State.presentedDapp,
			action: AuthorizedDapps.Destination.Action.presentedDapp,
			destination: { DappDetails.View(store: $0) }
		)
	}
}
