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

	public var getP2PClients: GetP2PClients
	public var storeP2PClient: StoreP2PClient
	public var deleteP2PClientByPassword: DeleteP2PClientByPassword
	public var addP2PWithPassword: AddP2PWithPassword

	public var receiveMessages: ReceiveMessages
	public var sendMessage: SendMessage
}

extension P2PConnectivityClient {
	public typealias LoadFromProfileAndConnectAll = @Sendable () async -> Void
	public typealias DisconnectAndRemoveAll = @Sendable () async -> Void

	public typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	public typealias GetP2PClients = @Sendable () async throws -> OrderedSet<P2PClient>
	public typealias StoreP2PClient = @Sendable (P2PClient) async throws -> Void

	public typealias AddP2PWithPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteP2PClientByPassword = @Sendable (ConnectionPassword) async throws -> Void

	public typealias ReceiveMessages = @Sendable () async -> AsyncStream<P2P.RTCIncommingMessageResult>
	public typealias SendMessage = @Sendable (P2P.RTCOutgoingMessage) async throws -> Void
}
