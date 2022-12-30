import Common
import ComposableArchitecture
import DesignSystem
import Foundation
import NewConnectionFeature
import P2PConnectivityClient
import SharedModels
import SwiftUI

// MARK: - ManageP2PClients.View
public extension ManageP2PClients {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClients>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageP2PClients.View {
	var body: some View {
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

private extension ManageP2PClients.View {
	func manageP2PClientsView(
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
								state: \.connections,
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
			}
		}
		.task { @MainActor in
			await ViewStore(store.stateless).send(.view(.task)).finish()
		}
	}
}

// MARK: - ManageP2PClients.View.ViewState
public extension ManageP2PClients.View {
	struct ViewState: Equatable {
		public var connections: IdentifiedArrayOf<P2P.ClientWithConnectionStatus>
		public var canAddMoreConnections: Bool {
			// FIXME: Post betanet we should allow multiple connections...
			connections.isEmpty
		}

		init(state: ManageP2PClients.State) {
			connections = state.connections
		}
	}
}

#if DEBUG
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
