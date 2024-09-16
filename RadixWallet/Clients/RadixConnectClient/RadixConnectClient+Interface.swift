import Sargon

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
	/// Connects to the p2p links stored in secure storage.
	public var loadP2PLinksAndConnectAll: LoadFromProfileAndConnectAll
	public var disconnectAll: DisconnectAll

	/// Connects to a given list of p2p links, those will not be stored in secure storage.
	public var connectToP2PLinks: ConnectToP2PLinks

	public var getLocalNetworkAccess: GetLocalNetworkAccess

	public var getP2PLinks: GetP2PLinks
	public var getP2PLinksWithConnectionStatusUpdates: GetP2PLinksWithConnectionStatusUpdates
	public var idsOfConnectedPeerConnections: IDsOfConnectedPeerConnections
	public var updateOrAddP2PLink: UpdateOrAddP2PLink
	public var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	public var connectP2PLink: ConnectP2PLink

	public var receiveMessages: ReceiveMessages

	public var sendResponse: SendResponse
	public var sendRequest: SendRequest

	public var handleDappDeepLink: HandleDappDeepLink
}

extension RadixConnectClient {
	// Returns an async sequence of connection events
	public typealias LoadFromProfileAndConnectAll = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>

	public typealias DisconnectAll = @Sendable () async -> Void

	public typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	public typealias GetP2PLinks = @Sendable () async throws -> OrderedSet<P2PLink>
	public typealias GetP2PLinksWithConnectionStatusUpdates = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>
	public typealias IDsOfConnectedPeerConnections = @Sendable () async -> [PeerConnectionID]

	public typealias UpdateOrAddP2PLink = @Sendable (P2PLink) async throws -> Void

	public typealias ConnectP2PLink = @Sendable (P2PLink) async throws -> Void
	public typealias DeleteP2PLinkByPassword = @Sendable (RadixConnectPassword) async throws -> Void

	public typealias ReceiveMessages = @Sendable () async -> AnyAsyncSequence<P2P.RTCIncomingMessage>

	public typealias SendRequest = @Sendable (_ request: P2P.RTCOutgoingMessage.Request, _ sendStrategy: P2P.RTCOutgoingMessage.Request.SendStrategy) async throws -> Int

	public typealias SendResponse = @Sendable (_ response: P2P.RTCOutgoingMessage.Response, _ origin: P2P.Route) async throws -> Void

	public typealias ConnectToP2PLinks = @Sendable (P2PLinks) async throws -> Void
	public typealias HandleDappDeepLink = @Sendable (URL) async throws -> Void
}
