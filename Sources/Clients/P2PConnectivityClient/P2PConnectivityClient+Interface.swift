import P2PConnection
import Prelude
import ProfileClient

// MARK: - DependencyValues
public extension DependencyValues {
	var p2pConnectivityClient: P2PConnectivityClient {
		get { self[P2PConnectivityClient.self] }
		set { self[P2PConnectivityClient.self] = newValue }
	}
}

// MARK: - P2PConnectivityClient

//  MARK: - P2PConnectivityClient
public struct P2PConnectivityClient: DependencyKey, Sendable {
	public var loadFromProfileAndConnectAll: LoadFromProfileAndConnectAll
	public var disconnectAndRemoveAll: DisconnectAndRemoveAll

	public var getLocalNetworkAccess: GetLocalNetworkAccess

	//	public var getP2PClients: GetP2PClients
	public var getP2PClientIDs: GetP2PClientIDs
	public var getP2PClientsByIDs: GetP2PClientsByIDs

	public var addP2PClientWithConnection: AddP2PClientWithConnection
	public var deleteP2PClientByID: DeleteP2PClientByID

	public var getConnectionStatusAsyncSequence: GetConnectionStatusAsyncSequence
	public var getRequestsFromP2PClientAsyncSequence: GetRequestsFromP2PClientAsyncSequence
	public var sendMessageReadReceipt: SendMessageReadReceipt
	public var sendMessage: SendMessage

	// MARK: Debug functionality
	public var _sendTestMessage: _SendTestMessage
	public var _debugWebsocketStatusAsyncSequence: DebugGetWebsocketStatusAsyncSequence
	public var _debugDataChannelStatusAsyncSequence: DebugGetDataChannelStatusAsyncSequence
}

public extension P2PConnectivityClient {
	typealias LoadFromProfileAndConnectAll = @Sendable () async throws -> Void
	typealias DisconnectAndRemoveAll = @Sendable () async -> Void

	typealias GetAsyncSequenceOfByP2PClientID<Value> = @Sendable (P2PClient.ID) async throws -> AnyAsyncSequence<Value>

	typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	typealias GetP2PClientIDs = @Sendable () async throws -> AnyAsyncSequence<OrderedSet<P2PClient.ID>>
	typealias GetP2PClientsByIDs = @Sendable (OrderedSet<P2PClient.ID>) async throws -> OrderedSet<P2PClient>

	typealias AddP2PClientWithConnection = @Sendable (P2PClient) async throws -> Void
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void

	typealias GetConnectionStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<P2P.ClientWithConnectionStatus>
	typealias GetRequestsFromP2PClientAsyncSequence = GetAsyncSequenceOfByP2PClientID<P2P.RequestFromClient>

	typealias SendMessageReadReceipt = @Sendable (P2PClient.ID, P2PConnections.IncomingMessage) async throws -> Void
	typealias SendMessage = @Sendable (P2P.ResponseToClientByID) async throws -> P2P.SentResponseToClient

	// MARK: Debug functionality
	typealias _SendTestMessage = @Sendable (P2PClient.ID, String) async throws -> Void
	typealias DebugGetWebsocketStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<WebSocketState>
	typealias DebugGetDataChannelStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<DataChannelState>
}
