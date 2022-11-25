import Common
import ComposableArchitecture
import ConnectUsingPasswordFeature
import DesignSystem
import Foundation
import InputPasswordFeature
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
							state: \.inputP2PConnectionPassword,
							action: { .child(.inputP2PConnectionPassword($0)) }
						),
						then: { inputPasswordStore in
							ForceFullScreen {
								VStack {
									NavigationBar(
										titleText: "New Connection",
										leadingItem: CloseButton {
											viewStore.send(.dismissNewConnectionFlowButtonTapped)
										}
									)
									.foregroundColor(.app.gray1)

									InputPassword.View(store: inputPasswordStore)
										.buttonStyle(.secondaryRectangular())

									Spacer()
								}
								.padding(.medium3)
							}
						}
					)
					.zIndex(1)

					IfLetStore(
						store.scope(
							state: \.connectUsingPassword,
							action: { .child(.connectUsingPassword($0)) }
						),
						then: { connectUsingPasswordStore in
							ForceFullScreen {
								ConnectUsingPassword.View(store: connectUsingPasswordStore)
							}
							.padding()
						}
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
					titleText: "P2P Connections",
					leadingItem: BackButton {
						viewStore.send(.dismissButtonTapped)
					}
				)
				.foregroundColor(.app.gray1)
				.padding([.horizontal, .top], .medium3)

				VStack {
					ScrollView {
						VStack {
							ForEachStore(
								store.scope(
									state: \.connections,
									action: { .child(.connection(id: $0, action: $1)) }
								),
								content: ManageP2PClient.View.init(store:)
							)
						}
					}

					Button("Add new connection") {
						viewStore.send(.addNewConnectionButtonTapped)
					}
					.enabled(viewStore.canAddMoreConnections)
					.buttonStyle(.primaryRectangular)

					Spacer()
				}
				.padding([.horizontal, .bottom], .medium1)
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
