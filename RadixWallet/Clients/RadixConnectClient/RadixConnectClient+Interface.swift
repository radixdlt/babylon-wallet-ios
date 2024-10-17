import Sargon

// MARK: - DependencyValues
extension DependencyValues {
	var radixConnectClient: RadixConnectClient {
		get { self[RadixConnectClient.self] }
		set { self[RadixConnectClient.self] = newValue }
	}
}

// MARK: - P2P.LinkConnectionUpdate
extension P2P {
	struct LinkConnectionUpdate: Sendable, Hashable {
		let link: P2PLink
		let idsOfConnectedPeerConnections: [PeerConnectionID]
		var hasAnyConnectedPeers: Bool {
			!idsOfConnectedPeerConnections.isEmpty
		}
	}
}

// MARK: - RadixConnectClient
struct RadixConnectClient: DependencyKey, Sendable {
	/// Connects to the p2p links stored in secure storage.
	var loadP2PLinksAndConnectAll: LoadFromProfileAndConnectAll
	var disconnectAll: DisconnectAll

	/// Connects to a given list of p2p links, those will not be stored in secure storage.
	var connectToP2PLinks: ConnectToP2PLinks

	var getLocalNetworkAccess: GetLocalNetworkAccess

	var getP2PLinks: GetP2PLinks
	var getP2PLinksWithConnectionStatusUpdates: GetP2PLinksWithConnectionStatusUpdates
	var idsOfConnectedPeerConnections: IDsOfConnectedPeerConnections
	var updateOrAddP2PLink: UpdateOrAddP2PLink
	var deleteP2PLinkByPassword: DeleteP2PLinkByPassword
	var connectP2PLink: ConnectP2PLink

	var receiveMessages: ReceiveMessages

	var sendResponse: SendResponse
	var sendRequest: SendRequest

	var handleDappDeepLink: HandleDappDeepLink
}

extension RadixConnectClient {
	// Returns an async sequence of connection events
	typealias LoadFromProfileAndConnectAll = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>

	typealias DisconnectAll = @Sendable () async -> Void

	typealias GetLocalNetworkAccess = @Sendable () async -> Bool

	typealias GetP2PLinks = @Sendable () async throws -> OrderedSet<P2PLink>
	typealias GetP2PLinksWithConnectionStatusUpdates = @Sendable () async -> AnyAsyncSequence<[P2P.LinkConnectionUpdate]>
	typealias IDsOfConnectedPeerConnections = @Sendable () async -> [PeerConnectionID]

	typealias UpdateOrAddP2PLink = @Sendable (P2PLink) async throws -> Void

	typealias ConnectP2PLink = @Sendable (P2PLink) async throws -> Void
	typealias DeleteP2PLinkByPassword = @Sendable (RadixConnectPassword) async throws -> Void

	typealias ReceiveMessages = @Sendable () async -> AnyAsyncSequence<P2P.RTCIncomingMessage>

	typealias SendRequest = @Sendable (_ request: P2P.RTCOutgoingMessage.Request, _ sendStrategy: P2P.RTCOutgoingMessage.Request.SendStrategy) async throws -> Int

	typealias SendResponse = @Sendable (_ response: P2P.RTCOutgoingMessage.Response, _ origin: P2P.Route) async throws -> Void

	typealias ConnectToP2PLinks = @Sendable (P2PLinks) async throws -> Void
	typealias HandleDappDeepLink = @Sendable (URL) async throws -> Void
}
