import FeaturePrelude

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
					Text(L10n.AuthorizedDapps.intro)
						.textBlock
						.padding(.vertical, .medium3)

					Separator()
						.padding(.vertical, .medium3)

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							Card_ {
								viewStore.send(.didSelectDapp(dApp.id))
							} contents: {
								PlainListRow_(title: dApp.name) {
									DappThumbnail(.known(dApp.thumbnail))
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
			.navigationDestination(store: store.presentedDapp) { store in
				DappDetails.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

extension AuthorizedDapps.State {
	var viewState: AuthorizedDapps.ViewState {
		let dAppViewStates = dApps.map {
			AuthorizedDapps.ViewState.Dapp(id: $0.id, name: $0.displayName.rawValue, thumbnail: thumbnails[$0.id])
		}

		return .init(dApps: .init(uniqueElements: dAppViewStates))
	}
}

extension AuthorizedDapps.Store {
	var presentedDapp: PresentationStoreOf<DappDetails> {
		scope(state: \.$presentedDapp) { .child(.presentedDapp($0)) }
	}
}
