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
			ScrollView {
				Text(L10n.ManageP2PClients.p2PConnectionsSubtitle)
					.foregroundColor(.app.gray2)
					.textStyle(.body1HighImportance)
					.flushedLeft
					.padding([.horizontal, .top], .medium3)
					.padding(.bottom, .small2)

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
				.controlState(viewStore.canAddMoreConnections ? .enabled : .disabled)
				.buttonStyle(.secondaryRectangular(
					shouldExpand: true,
					image: .init(asset: AssetResource.qrCodeScanner)
				))
				.padding(.horizontal, .medium3)
				.padding(.vertical, .large1)
			}
			.navigationTitle(L10n.ManageP2PClients.p2PConnectionsTitle)
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /ManageP2PClients.Destinations.State.newConnection,
				action: ManageP2PClients.Destinations.Action.newConnection,
				content: { NewConnection.View(store: $0) }
			)
		}
	}
}

// MARK: - ManageP2PClients.View.ViewState
extension ManageP2PClients.View {
	public struct ViewState: Equatable {
		public var clients: IdentifiedArrayOf<ManageP2PClient.State>
		public var canAddMoreConnections: Bool {
			// FIXME: Post betanet we should allow multiple connections...
			clients.isEmpty
		}

		init(state: ManageP2PClients.State) {
			clients = state.clients
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ManageP2PClients_Preview: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			ManageP2PClients.View(
				store: .init(
					initialState: .previewValue,
					reducer: ManageP2PClients()
				)
			)
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}
}
#endif
