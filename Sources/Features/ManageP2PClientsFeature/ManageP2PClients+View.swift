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
			VStack {
				NavigationBar(
					titleText: L10n.ManageP2PClients.p2PConnectionsTitle,
					leadingItem: BackButton {
						viewStore.send(.dismissButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				VStack(alignment: .leading) {
					ScrollView {
						VStack(alignment: .leading) {
							ForEachStore(
								store.scope(
									state: \.connections,
									action: { .child(.connection(id: $0, action: $1)) }
								),
								content: { ManageP2PClient.View(store: $0) }
							)
						}
					}

					Button(L10n.ManageP2PClients.newConnectionButtonTitle) {
						viewStore.send(.addNewConnectionButtonTapped)
					}
					.enabled(viewStore.canAddMoreConnections)
					.buttonStyle(.primaryRectangular)

					Spacer()
				}
				.padding([.bottom, .horizontal], .medium3)
				.onAppear { viewStore.send(.viewAppeared) }
			}
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
