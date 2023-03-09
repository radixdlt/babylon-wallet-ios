import FeaturePrelude
import NewConnectionFeature
import RadixConnectClient

// MARK: - ManageP2PClients.View
extension ManageP2PClients {
	public struct ViewState: Equatable {
		public let clients: IdentifiedArrayOf<ManageP2PClient.State>

		init(state: ManageP2PClients.State) {
			clients = state.clients
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ManageP2PClients>

		public init(store: StoreOf<ManageP2PClients>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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

extension ManageP2PClients.State {
	public static let previewValue: Self = .init()
}
#endif
