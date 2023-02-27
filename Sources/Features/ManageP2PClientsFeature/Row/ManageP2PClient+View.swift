import FeaturePrelude
import P2PConnection

// MARK: - ManageP2PClient.View
extension ManageP2PClient {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.StoreOf<ManageP2PClient>
		public let store: Store
		public init(store: Store) {
			self.store = store
		}
	}
}

extension ManageP2PClient.View {
	public var body: some View {
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
//				#if DEBUG
//				debugView(viewStore: viewStore)
//				#endif
			}
			.onAppear {
				viewStore.send(.viewAppeared)
			}
		}
	}
}

// MARK: - ManageP2PClient.View.ViewState
extension ManageP2PClient.View {
	public struct ViewState: Equatable {
		public var connectionName: String

		#if DEBUG
		public var connectionStatus: ConnectionStatus
		public var dataChannelStatus: DataChannelState
		public var webSocketStatus: WebSocketState
		public var connectionID: String
		#endif

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
			#endif
		}
	}
}

// MARK: DEBUG

#if DEBUG
extension ManageP2PClient.View {
	@ViewBuilder
	fileprivate func debugView(
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

extension ManageP2PClient.View.ViewState {
	fileprivate var connectionStatusDescription: String {
		connectionStatus.rawValue.capitalized
	}

	fileprivate var connectionStatusColor: Color {
		switch connectionStatus {
		case .disconnected, .failed, .closed: return .closed
		case .closing: return .closing
		case .new: return .new
		case .connecting: return .connecting
		case .connected: return .connected
		}
	}

	fileprivate var websocketConnectionStatusDescription: String {
		webSocketStatus.description.capitalized
	}

	fileprivate var websocketConnectionStatusColor: Color {
		switch webSocketStatus {
		case .new: return .new
		case .connecting: return .connecting
		case .open: return .connected
		case .closing: return .closing
		case .closed: return .closed
		}
	}

	fileprivate var dataChannelReadyStateDescription: String {
		dataChannelStatus.description
	}

	fileprivate var dataChannelReadyStateColor: Color {
		switch dataChannelStatus {
		case .closed: return .closed
		case .open: return .connected
		case .closing: return .closing
		case .connecting: return .connecting
		}
	}
}

extension Color {
	fileprivate static let new: Self = .gray
	fileprivate static let connecting: Self = .yellow
	fileprivate static let closing: Self = .orange
	fileprivate static let connected: Self = .green
	fileprivate static let closed: Self = .red
}

import SwiftUI // NB: necessary for previews to appear

struct ManageP2PClient_Preview: PreviewProvider {
	static var previews: some View {
		ManageP2PClient.View(
			store: .init(
				initialState: .previewValue,
				reducer: ManageP2PClient()
			)
		)
	}
}
#endif
