import FeaturePrelude

// MARK: - ConnectedDApps.View
extension ConnectedDApps {
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

public extension ConnectedDApps.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: 0) {
					Text(L10n.ConnectedDApps.intro)
						.textBlock
						.padding(.vertical, .medium3)

					Separator()

					VStack(spacing: .medium3) {
						ForEach(viewStore.dApps) { dApp in
							RadixCard {
								PlainListRow(title: dApp.displayName.rawValue) {
									viewStore.send(.didSelectDApp(dApp.id))
								} icon: {
									DAppPlaceholder()
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
			.navBarTitle(L10n.ConnectedDApps.title)
			.navigationDestination(store: store.selectedDApp) { store in
				DAppProfile.View(store: store)
			}
		}
	}
}

// MARK: - Extensions

extension ConnectedDApps.State {
	var viewState: ConnectedDApps.ViewState {
		.init(dApps: dApps)
	}
}

extension ConnectedDApps.Store {
	var selectedDApp: PresentationStoreOf<DAppProfile> {
		scope(state: \.$selectedDApp) { .child(.selectedDApp($0)) }
	}
}
