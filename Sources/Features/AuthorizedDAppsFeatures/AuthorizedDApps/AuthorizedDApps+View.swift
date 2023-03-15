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
		let dApps: OnNetwork.AuthorizedDapps
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

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							Card {
								PlainListRow(title: dApp.displayName.rawValue) {
									viewStore.send(.didSelectDapp(dApp.id))
								} icon: {
									DappPlaceholder()
								}
							}
						}
					}
					.animation(.easeInOut, value: viewStore.dApps)

					Spacer()
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
		.init(dApps: dApps)
	}
}

extension AuthorizedDapps.Store {
	var presentedDapp: PresentationStoreOf<DappDetails> {
		scope(state: \.$presentedDapp) { .child(.presentedDapp($0)) }
	}
}
