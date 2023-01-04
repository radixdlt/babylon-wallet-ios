import ComposableArchitecture
import DesignSystem
import P2PConnection
import Resources
import SharedModels
import SwiftUI

// MARK: - ManageP2PClient.View
public extension ManageP2PClient {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClient>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

public extension ManageP2PClient.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			HStack {
				VStack(alignment: .leading) {
					Text(viewStore.connectionName)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					#if DEBUG
					Text(L10n.ManageP2PClients.connectionID(viewStore.connectionID))
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)

					HStack {
						Text("RTC Connection Status")
						Text(viewStore.connectionStatusDescription)
							.foregroundColor(.app.gray1)
							.textStyle(.body2Regular)

						Circle()
							.fill(viewStore.connectionStatusColor)
							.frame(width: 10)
					}

					HStack {
						Text("WebSocket Connection Status")
						Text(viewStore.wsConnectionStatusDescription)
							.foregroundColor(.app.gray1)
							.textStyle(.body2Regular)

						Circle()
							.fill(viewStore.wsConnectionStatusColor)
							.frame(width: 10)
					}

					Button(L10n.ManageP2PClients.sendTestMessageButtonTitle) {
						viewStore.send(.sendTestMessageButtonTapped)
					}
					.buttonStyle(.secondaryRectangular())
					#endif // DEBUG
				}

				Spacer()

				Button(
					action: {
						viewStore.send(.deleteConnectionButtonTapped)
					},
					label: {
						Image(asset: AssetResource.delete)
							.foregroundColor(.app.gray1)
					}
				)
			}
			.onAppear {
				viewStore.send(.viewAppeared)
			}
		}
	}
}

// MARK: - ManageP2PClient.View.ViewState
public extension ManageP2PClient.View {
	struct ViewState: Equatable {
		public var connectionName: String
		#if DEBUG
		public var connectionStatus: ConnectionStatus
		public var webSocketStatus: WebSocketState
		public var connectionID: String
		#endif // DEBUG
		init(state: ManageP2PClient.State) {
			connectionName = state.client.displayName

			#if DEBUG
			connectionStatus = state.connectionStatus
			webSocketStatus = state.webSocketState
			connectionID = [
				state.client.id.hex().prefix(4),
				"...",
				state.client.id.hex().suffix(6),
			].joined()
			#endif // DEBUG
		}
	}
}

#if DEBUG
public extension ManageP2PClient.View.ViewState {
	var connectionStatusDescription: String {
		connectionStatus.rawValue.capitalized
	}

	var connectionStatusColor: Color {
		switch connectionStatus {
		case .disconnected, .failed, .closed, .closing:
			return .red
		case .connecting, .new:
			return .yellow
		case .connected:
			return .green
		}
	}

	var wsConnectionStatusDescription: String {
		webSocketStatus.description.capitalized
	}

	var wsConnectionStatusColor: Color {
		switch webSocketStatus {
		case .new: return .blue
		case .connecting: return .yellow
		case .open: return .green
		case .closing: return .orange
		case .closed: return .red
		}
	}
}
#endif // DEBUG
