import FeaturePrelude
import NewConnectionFeature
import P2PConnectivityClient

// MARK: - ManageP2PClients.View
extension ManageP2PClients {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClients>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManageP2PClients.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					manageP2PClientsView(viewStore: viewStore)
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.newConnection,
							action: { .child(.newConnection($0)) }
						),
						then: { NewConnection.View(store: $0) }
					)
					.zIndex(2)
				}
			}
		}
	}
}

extension ManageP2PClients.View {
	fileprivate func manageP2PClientsView(
		viewStore: ViewStore<ViewState, ManageP2PClients.Action.ViewAction>
	) -> some View {
		ForceFullScreen {
			VStack(spacing: .zero) {
				NavigationBar(
					titleText: L10n.ManageP2PClients.p2PConnectionsTitle,
					leadingItem: BackButton {
						viewStore.send(.dismissButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				Separator()

				ScrollView {
					HStack {
						Text(L10n.ManageP2PClients.p2PConnectionsSubtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body1HighImportance)
							.padding([.horizontal, .top], .medium3)
							.padding(.bottom, .small2)

						Spacer()
					}

					Separator()

					VStack(alignment: .leading) {
						ForEachStore(
							store.scope(
								state: \.clients,
								action: { .child(.connection(id: $0, action: $1)) }
							),
							content: {
								ManageP2PClient.View(store: $0)
									.padding(.medium3)

								Separator()
							}
						)
					}

					Button(L10n.ManageP2PClients.newConnectionButtonTitle) {
						viewStore.send(.addNewConnectionButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(
						shouldExpand: true,
						image: .init(asset: AssetResource.qrCodeScanner)
					))
					.padding(.horizontal, .medium3)
					.padding(.vertical, .large1)
				}
			}
		}
		.task { @MainActor in
			await ViewStore(store.stateless).send(.view(.task)).finish()
		}
	}
}

// MARK: - ManageP2PClients.View.ViewState
extension ManageP2PClients.View {
	public struct ViewState: Equatable {
		public var clients: IdentifiedArrayOf<ManageP2PClient.State>

		init(state: ManageP2PClients.State) {
			clients = state.clients
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ManageP2PClients_Preview: PreviewProvider {
	static var previews: some View {
		ManageP2PClients.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageP2PClients()
			)
		)
	}
}
#endif
