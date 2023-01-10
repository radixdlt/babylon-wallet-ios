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
			VStack(alignment: .leading, spacing: 2) {
				HStack {
					VStack(alignment: .leading) {
						Text(viewStore.connectionName)
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)
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
				#if DEBUG
				debugView(viewStore: viewStore)
				#endif
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
		public var dataChannelStatus: DataChannelState
		public var webSocketStatus: WebSocketState
		public var connectionID: String
		#endif // DEBUG

		init(state: ManageP2PClient.State) {
			connectionName = state.client.displayName

			#if DEBUG
			connectionStatus = state.connectionStatus
			webSocketStatus = state.webSocketState
			dataChannelStatus = state.dataChannelStatus
			connectionID = [
				state.client.id.hex().prefix(4),
				"...",
				state.client.id.hex().suffix(6),
			].joined()
			#endif // DEBUG
		}
	}
}

// MARK: DEBUG

#if DEBUG
private extension ManageP2PClient.View {
	@ViewBuilder
	func debugView(
		viewStore: ViewStore<ViewState, ManageP2PClient.Action.ViewAction>
	) -> some View {
		Text(L10n.ManageP2PClients.connectionID(viewStore.connectionID))

		ConnectionInfoView(viewStore.overallConnectionInfo)
		ConnectionInfoView(viewStore.webSocketConnectionInfo)
		ConnectionInfoView(viewStore.dataChannelConnectionInfo)

		Button(L10n.ManageP2PClients.sendTestMessageButtonTitle) {
			viewStore.send(.sendTestMessageButtonTapped)
		}
		.buttonStyle(.secondaryRectangular())
	}
}

struct ConnectionInfoView: SwiftUI.View {
	let connectionInfo: ConnectionInfo
	init(_ connectionInfo: ConnectionInfo) {
		self.connectionInfo = connectionInfo
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			HStack {
				Text(connectionInfo.title)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)

				Circle()
					.fill(connectionInfo.color)
					.frame(width: 10)

				Text(connectionInfo.status)
					.foregroundColor(.app.gray2)
					.textStyle(.body1Link)
			}

			Text(connectionInfo.description)
				.foregroundColor(.app.gray3)
				.textStyle(.body2Regular)
		}
	}
}

struct ConnectionInfo: Equatable {
	let title: String
	let description: String
	let color: Color
	let status: String
}

extension ManageP2PClient.View.ViewState {
	var overallConnectionInfo: ConnectionInfo {
		.init(
			title: "Connection Status",
			description: "Aggregated status of P2P connection",
			color: connectionStatusColor,
			status: connectionStatusDescription
		)
	}

	var webSocketConnectionInfo: ConnectionInfo {
		.init(
			title: "Websocket Status",
			description: "Signaling Server websocket connection status",
			color: websocketConnectionStatusColor,
			status: websocketConnectionStatusDescription
		)
	}

	var dataChannelConnectionInfo: ConnectionInfo {
		.init(
			title: "DataChannel readyStatus",
			description: "ReadyState as notified by RTC callbacks",
			color: dataChannelReadyStateColor,
			status: dataChannelReadyStateDescription
		)
	}
}

private extension ManageP2PClient.View.ViewState {
	var connectionStatusDescription: String {
		connectionStatus.rawValue.capitalized
	}

	var connectionStatusColor: Color {
		switch connectionStatus {
		case .disconnected, .failed, .closed: return .closed
		case .closing: return .closing
		case .new: return .new
		case .connecting: return .connecting
		case .connected: return .connected
		}
	}

	var websocketConnectionStatusDescription: String {
		webSocketStatus.description.capitalized
	}

	var websocketConnectionStatusColor: Color {
		switch webSocketStatus {
		case .new: return .new
		case .connecting: return .connecting
		case .open: return .connected
		case .closing: return .closing
		case .closed: return .closed
		}
	}

	var dataChannelReadyStateDescription: String {
		dataChannelStatus.description
	}

	var dataChannelReadyStateColor: Color {
		switch dataChannelStatus {
		case .closed: return .closed
		case .open: return .connected
		case .closing: return .closing
		case .connecting: return .connecting
		}
	}
}

private extension Color {
	static let new: Self = .gray
	static let connecting: Self = .yellow
	static let closing: Self = .orange
	static let connected: Self = .green
	static let closed: Self = .red
}
#endif // DEBUG
