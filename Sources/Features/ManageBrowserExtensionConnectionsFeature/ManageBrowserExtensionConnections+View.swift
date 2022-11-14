import BrowserExtensionsConnectivityClient
import Common
import ComposableArchitecture
import ConnectUsingPasswordFeature
import DesignSystem
import Foundation
import IncomingConnectionRequestFromDappReviewFeature
import InputPasswordFeature
import SwiftUI

// MARK: - ManageBrowserExtensionConnections.View
public extension ManageBrowserExtensionConnections {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageBrowserExtensionConnections>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageBrowserExtensionConnections.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ZStack {
					manageBrowserExtensionConnectionsView(viewStore: viewStore)
						.zIndex(0)

					IfLetStore(
						store.scope(
							state: \.inputBrowserExtensionConnectionPassword,
							action: { .child(.inputBrowserExtensionConnectionPassword($0)) }
						),
						then: { inputPasswordStore in
							Screen(
								title: "New Connection",
								navBarActionStyle: .close,
								action: { viewStore.send(.dismissNewConnectionFlowButtonTapped) }
							) {
								VStack {
									InputPassword.View(store: inputPasswordStore)
								}
								.padding()
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

private extension ManageBrowserExtensionConnections.View {
	func manageBrowserExtensionConnectionsView(
		viewStore: ViewStore<ViewState, ManageBrowserExtensionConnections.Action.ViewAction>
	) -> some View {
		Screen(
			title: "Browser Connections",
			navBarActionStyle: .back,
			action: { viewStore.send(.dismissButtonTapped) }
		) {
			VStack {
				ScrollView {
					VStack {
						ForEachStore(
							store.scope(
								state: \.connections,
								action: { .child(.connection(id: $0, action: $1)) }
							),
							content: ManageBrowserExtensionConnection.View.init(store:)
						)
					}
				}
				PrimaryButton(title: "Add new connection", isEnabled: viewStore.canAddMoreBrowserExtensionConnections) { viewStore.send(.addNewConnectionButtonTapped) }
				Spacer()
			}
			.onAppear { viewStore.send(.viewAppeared) }
		}
	}
}

// MARK: - ManageBrowserExtensionConnections.View.ViewState
public extension ManageBrowserExtensionConnections.View {
	struct ViewState: Equatable {
		public var connections: IdentifiedArrayOf<BrowserExtensionWithConnectionStatus>
		public var canAddMoreBrowserExtensionConnections: Bool {
			// FIXME: Post betanet we should allow multiple connections...
			connections.isEmpty
		}

		init(state: ManageBrowserExtensionConnections.State) {
			connections = state.connections
		}
	}
}
