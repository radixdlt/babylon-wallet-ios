import ClientPrelude
import RadixConnect

// MARK: - DependencyValues
extension DependencyValues {
	public var radixConnectClient: RadixConnectClient {
		get { self[RadixConnectClient.self] }
		set { self[RadixConnectClient.self] = newValue }
	}
}

// MARK: - P2P.LinkConnectionUpdate
extension P2P {
	public struct LinkConnectionUpdate: Sendable, Hashable {
		public let link: P2PLink
		public let idsOfConnectedPeerConnections: [PeerConnectionID]
		public var hasAnyConnectedPeers: Bool {
			!idsOfConnectedPeerConnections.isEmpty
		}
	}
}

// MARK: - RadixConnectClient
public struct RadixConnectClient: DependencyKey, Sendable {
	public var loadFromProfileAndConnectAll: LoadFromProfileAndConnectAll
	public var disconnectAndRemoveAll: DisconnectAndRemoveAll
	public var disconnectAll: DisconnectAll

	public var getLocalNetworkAccess: GetLocalNetworkAccess

	public var getP2PLinks: GetP2PLinks
	public var getP2PLinksWithConnectionStatusUpdates: GetP2PLinksWithConnectionStatusUpdates
	public var storeP2PLink: StoreP2PLink
	public var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	public var addP2PWithPassword: AddP2PWithPassword

	public var receiveMessages: ReceiveMessages

	public var sendResponse: SendResponse
	public var sendRequest: SendRequest
}

extension RadixConnectClient {
	// Returns an async sequence of connection events
	public typealias LoadFromProfileAndConnectAll = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>

	public typealias DisconnectAndRemoveAll = @Sendable () async -> Void
	public typealias DisconnectAll = @Sendable () async -> Void

	public typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	public typealias GetP2PLinks = @Sendable () async throws -> OrderedSet<P2PLink>
	public typealias GetP2PLinksWithConnectionStatusUpdates = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>

	public typealias StoreP2PLink = @Sendable (P2PLink) async throws -> Void

	public typealias AddP2PWithPassword = @Sendable (ConnectionPassword) async throws -> Void
	public typealias DeleteP2PLinkByPassword = @Sendable (ConnectionPassword) async throws -> Void

	public typealias ReceiveMessages = @Sendable () async -> AnyAsyncSequence<P2P.RTCIncomingMessage>

	public typealias SendRequest = @Sendable (_ request: P2P.RTCOutgoingMessage.Request, _ sendStrategy: P2P.RTCOutgoingMessage.Request.SendStrategy) async throws -> Int

	public typealias SendResponse = @Sendable (_ response: P2P.RTCOutgoingMessage.Response, _ origin: P2P.RTCRoute) async throws -> Void
}
