import ClientPrelude
import RadixConnect

// MARK: - DependencyValues
extension DependencyValues {
	public var p2pConnectivityClient: P2PConnectivityClient {
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
	public var addP2PWithSecrets: AddP2PWithPassword

//	public var getConnectionStatusAsyncSequence: GetConnectionStatusAsyncSequence
	public var receiveMessages: ReceiveMessages
	public var sendMessage: SendMessage

	// MARK: Debug functionality
//	public var _sendTestMessage: _SendTestMessage
//	public var _debugWebsocketStatusAsyncSequence: DebugGetWebsocketStatusAsyncSequence
//	public var _debugDataChannelStatusAsyncSequence: DebugGetDataChannelStatusAsyncSequence
}

extension P2PConnectivityClient {
	public typealias LoadFromProfileAndConnectAll = @Sendable () async throws -> Void
	public typealias DisconnectAndRemoveAll = @Sendable () async -> Void

//	public typealias GetAsyncSequenceOfByP2PClientID<Value> = @Sendable (P2PClient.ID) async throws -> AnyAsyncSequence<Value>

	public typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	public typealias GetP2PClientIDs = @Sendable () async throws -> AnyAsyncSequence<OrderedSet<P2PClient.ID>>
	public typealias GetP2PClientsByIDs = @Sendable (OrderedSet<P2PClient.ID>) async throws -> OrderedSet<P2PClient>

	public typealias AddP2PClientWithConnection = @Sendable (P2PClient) async throws -> Void
	public typealias AddP2PWithPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void

//	public typealias GetConnectionStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<P2P.ClientWithConnectionStatus>
	public typealias ReceiveMessages = @Sendable () async throws -> AnyAsyncSequence<RTCIncommingMessageResult>

	public typealias SendMessage = @Sendable (RTCOutgoingMessage) async throws -> Void

	// MARK: Debug functionality
//	public typealias _SendTestMessage = @Sendable (P2PClient.ID, String) async throws -> Void
//	public typealias DebugGetWebsocketStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<WebSocketState>
//	public typealias DebugGetDataChannelStatusAsyncSequence = GetAsyncSequenceOfByP2PClientID<DataChannelState>
}
