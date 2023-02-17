import FeaturePrelude

// MARK: - ConnectedDapps.View
extension ConnectedDapps {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}

	struct ViewState: Equatable {
		let dApps: IdentifiedArrayOf<OnNetwork.ConnectedDapp>
	}
}

// MARK: - Body

public extension ConnectedDapps.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					Text(L10n.ConnectedDapps.intro)
						.textBlock
						.padding(.vertical, .medium3)

					Separator()

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							RadixCard {
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
			.navBarTitle(L10n.ConnectedDapps.title)
			.navigationDestination(store: store.presentedDapp) { store in
				DappDetails.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

extension ConnectedDapps.State {
	var viewState: ConnectedDapps.ViewState {
		.init(dApps: dApps)
	}
}

extension ConnectedDapps.Store {
	var presentedDapp: PresentationStoreOf<DappDetails> {
		scope(state: \.$presentedDapp) { .child(.presentedDapp($0)) }
	}
}
