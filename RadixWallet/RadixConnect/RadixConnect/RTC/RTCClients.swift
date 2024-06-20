import Sargon
import WebRTC

// MARK: - P2P.ClientConnectionsUpdate
extension P2P {
	public struct ClientConnectionsUpdate: Sendable, Hashable {
		public let clientID: Hash
		public fileprivate(set) var idsOfConnectedPeerConnections: [PeerConnectionID]
	}
}

// MARK: - RTCClients
/// Holds and manages all of added RTCClients
public actor RTCClients {
	public struct RTCClientDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"RTCClient did close, retry connecting the browser with the Wallet"
		}
	}

	// MARK: - Properties

	public var currentlyConnectedClients: [P2P.ClientConnectionsUpdate] {
		clientConnectionsUpdateSubject.value
	}

	// MARK: - Streams

	/// A **multicasted** async sequence for received message from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	public func connectClients() async -> AnyAsyncSequence<[P2P.ClientConnectionsUpdate]> {
		clientConnectionsUpdateSubject.share().eraseToAnyAsyncSequence()
	}

	/// Incoming peer messages. This is the single channel for the received messages from all RTCClients
	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	/// ICEConnectionStatus updates. This is the single channel for the status updates from all RTCClients
	private let clientConnectionsUpdateSubject: AsyncCurrentValueSubject<[P2P.ClientConnectionsUpdate]> = .init([])

	// MARK: - Config
	private let peerConnectionFactory: PeerConnectionFactory
	private let signalingServerBaseURL: URL

	// MARK: - Internal state
	private var clients: [RTCClient.ID: RTCClient] = [:]

	// MARK: - Initializers
	init(
		peerConnectionFactory: PeerConnectionFactory,
		signalingServerBaseURL: URL = SignalingClient.default
	) {
		self.peerConnectionFactory = peerConnectionFactory
		self.signalingServerBaseURL = signalingServerBaseURL
	}
}

extension RTCClients {
	// Initializer for public clients
	public init() {
		self.init(peerConnectionFactory: WebRTCFactory())
	}
}

extension RTCClients {
	// MARK: - Public API

	public func connect(
		_ p2pLink: P2PLink,
		isNewConnection: Bool,
		waitsForConnectionToBeEstablished: Bool = false
	) async throws {
		guard !clients.contains(where: { $0.key == p2pLink.connectionPassword }) else {
			loggerGlobal.notice("Ignored connecting RTCClient with connectionPassword/id: \(p2pLink.connectionPassword), since it is already in RTCClients.clients")
			return
		}
		let client = try makeRTCClient(p2pLink, isNewConnection: isNewConnection)
		if waitsForConnectionToBeEstablished {
			try await client.waitForFirstConnection()
		}
		add(client)
	}

	/// Disconnect and remove the RTCClient for the given connection password
	/// - Parameter password: The connection password identifying the RTCClient
	public func disconnectAndRemoveClient(_ password: RadixConnectPassword) async {
		await clients[password]?.cancel()
		clients.removeValue(forKey: password)

		var cur = clientConnectionsUpdateSubject.value
		if let index = cur.firstIndex(where: { $0.clientID == password.hash() }) {
			cur.remove(at: index)
			clientConnectionsUpdateSubject.send(cur)
		}
	}

	/// Disconnect and remove all RTCClients
	public func disconnectAndRemoveAll() async {
		for id in clients.keys {
			await disconnectAndRemoveClient(id)
		}
	}

	/// Sends a response back to `origin`.
	/// If the target RTCClient did close, an error will be thrown
	/// - Parameters:
	///   - response: response to send
	///   - origin: the sender of the original request we are responding to.
	public func sendResponse(
		_ response: P2P.RTCOutgoingMessage.Response,
		to origin: P2P.RTCRoute
	) async throws {
		guard let rtcClient = clients[origin.connectionId], await rtcClient.hasAnyActiveConnections() else {
			loggerGlobal.info("RTCClients: No Active Peer Connection to send back message to, creating anew")
			await disconnectAndRemoveClient(origin.connectionId)
			// missing client, create anew
			try await connect(
				origin.p2pLink,
				isNewConnection: false,
				waitsForConnectionToBeEstablished: true
			)
			try await clients[origin.connectionId]?.send(response: response, to: origin.peerConnectionId)
			loggerGlobal.info("RTCClients: Did send message over freshly established PeerConnection")
			return
		}

		try await rtcClient.send(
			response: response,
			to: origin.peerConnectionId
		)
	}

	/// Sends a `request` using `strategy` to find suitable recipients or recipient.
	/// If no suitable recipient can be found, an error will be thrown.
	/// - Parameters:
	///   - request: request to send
	///   - strategy: strategy used to find suitable recipients or recipient.
	/// - Returns: Number of peers we sent the message to
	public func sendRequest(
		_ request: P2P.RTCOutgoingMessage.Request,
		strategy sendStrategy: P2P.RTCOutgoingMessage.Request.SendStrategy
	) async throws -> Int {
		switch sendStrategy {
		case .broadcastToAllPeers:
			try await broadcastRequest(request)
		case let .broadcastToAllPeersWith(purpose):
			try await broadcastRequest(request, purpose: purpose)
		}
	}

	private func connectedClients(purpose: RadixConnectPurpose?) async -> NonEmpty<[RTCClient]>? {
		var connectedClient = [RTCClient]()
		let clients = clients.values.filter {
			guard let purpose else { return true }
			return $0.p2pLink.connectionPurpose == purpose
		}
		for client in clients {
			guard await client.hasAnyActiveConnections() else { continue }
			connectedClient.append(client)
		}
		return NonEmpty(rawValue: connectedClient)
	}

	/// Broadcasts a request to all peers
	/// - Parameters:
	///   - request: request to send
	/// - Returns: Number of peers we sent the message to
	private func broadcastRequest(
		_ request: P2P.RTCOutgoingMessage.Request,
		purpose: RadixConnectPurpose? = nil
	) async throws -> Int {
		guard let connectedClients = await connectedClients(purpose: purpose) else {
			throw NoConnectedClients()
		}
		return try await withThrowingTaskGroup(of: Int.self, returning: Int.self) { group in
			for client in connectedClients {
				guard !Task.isCancelled else {
					// We do not throw if cancelled, it is good we
					// manage to broadcast to SOME client (i.e. not ALL is required.)
					continue
				}
				_ = group.addTaskUnlessCancelled {
					try await client.broadcast(request: request)
					return 1
				}
			}

			if group.isEmpty {
				loggerGlobal.error("Failed to broadcast to any RTCClient")
			}

			try await group.waitForAll()
			return try await group.reduce(0, +)
		}
	}

	// MARK: - Private

	func add(_ client: RTCClient) {
		Task {
			for await update in client.idsOfConnectPeerConnectionsSubject {
				loggerGlobal.debug("RTCClients got iceConnectionUpdate: \(update)")
				var cur = clientConnectionsUpdateSubject.value
				if let index = cur.firstIndex(where: { $0.clientID == client.id.hash() }) {
					cur[index].idsOfConnectedPeerConnections = update
				} else {
					cur.append(.init(clientID: client.id.hash(), idsOfConnectedPeerConnections: update))
				}

				clientConnectionsUpdateSubject.send(cur)
			}
			loggerGlobal.notice("Stopped receiving ICEConnection states updates")
		}

		client.incomingMessages.subscribe(incomingMessagesSubject)
		self.clients[client.id] = client
	}

	func makeRTCClient(
		_ p2pLink: P2PLink,
		isNewConnection: Bool
	) throws -> RTCClient {
		let signalingClient = try SignalingClient(
			password: p2pLink.connectionPassword,
			baseURL: signalingServerBaseURL
		)
		let negotiator = PeerConnectionNegotiator(
			p2pLink: p2pLink,
			isNewConnection: isNewConnection,
			signalingClient: signalingClient,
			factory: peerConnectionFactory
		)
		let client = RTCClient(
			p2pLink: p2pLink,
			peerConnectionNegotiator: negotiator
		)

		return client
	}
}

// MARK: - NoConnectedClients
struct NoConnectedClients: Swift.Error {}

// MARK: - RTCClient
actor RTCClient {
	let id: ID
	let p2pLink: P2PLink

	let incomingMessages: AsyncStream<P2P.RTCIncomingMessage>
	private let incomingMessagesContinuation: AsyncStream<P2P.RTCIncomingMessage>.Continuation

	private let peerConnectionNegotiator: PeerConnectionNegotiator
	private var peerConnections: [PeerConnectionClient.ID: PeerConnectionClient] = [:] {
		didSet {
			self.idsOfConnectPeerConnectionsSubject.send(Array(peerConnections.keys))
		}
	}

	private var connectionsTask: Task<Void, Error>?

	public func hasAnyActiveConnections() async -> Bool {
		!peerConnections.isEmpty
	}

	let idsOfConnectPeerConnectionsSubject: AsyncCurrentValueSubject<[PeerConnectionID]> = .init([])

	private let disconnectedPeerConnection: AsyncStream<PeerConnectionID>
	private let disconnectedPeerConnectionContinuation: AsyncStream<PeerConnectionID>.Continuation
	private var disconnectTask: Task<Void, Never>?

	init(
		p2pLink: P2PLink,
		peerConnectionNegotiator: PeerConnectionNegotiator
	) {
		self.id = p2pLink.connectionPassword
		self.p2pLink = p2pLink
		self.peerConnectionNegotiator = peerConnectionNegotiator
		(incomingMessages, incomingMessagesContinuation) = AsyncStream.makeStream()

		(disconnectedPeerConnection, disconnectedPeerConnectionContinuation) = AsyncStream.makeStream()

		Task {
			await listenForPeerConnections()
		}
	}
}

extension RTCClient {
	typealias ID = RadixConnectPassword
	public struct PeerConnectionDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"Peer Connection did close, retry the operation from dapp"
		}
	}
}

extension RTCClient {
	static var firstConnectionTimeout: Duration {
		.seconds(30)
	}

	/// Cancel all of the related operations allowing this RTCClient to be deallocated.
	func cancel() async {
		for peerConnection in peerConnections.values {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionNegotiator.cancel()
		incomingMessagesContinuation.finish()
		idsOfConnectPeerConnectionsSubject.send(.finished)
		disconnectedPeerConnectionContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func waitForFirstConnection() async throws {
		_ = try await doAsync(withTimeout: Self.firstConnectionTimeout) {
			_ = try await self.peerConnectionNegotiator.negotiationResults.first().get()
		}
	}

	func removePeerConnection(_ id: PeerConnectionID) async {
		await peerConnections[id]?.cancel()
		peerConnections.removeValue(forKey: id)
	}

	func broadcast(
		request: P2P.RTCOutgoingMessage.Request
	) async throws {
		guard await hasAnyActiveConnections() else {
			loggerGlobal.warning("Unable to broadcast, no connected PeerConnections.")
			throw NoConnectedClients()
		}

		let encoder = JSONEncoder()

		/// Important to not escape slashes for derivation paths, which otherwise will look:
		/// `m\/44H\/1022H\/0H\/0\/4H` but should be `m/44H/1022H/0H/0/4H` ofc.
		encoder.outputFormatting = [.withoutEscapingSlashes]

		let data = try encoder.encode(request)

		try await withThrowingTaskGroup(of: Void.self) { group in
			for client in peerConnections.values {
				guard !Task.isCancelled else {
					// We do not throw if cancelled, it is good we
					// manage to broadcast to SOME client (i.e. not ALL is required.)
					return
				}
				_ = group.addTaskUnlessCancelled {
					try await client.sendData(data)
				}
			}
			if group.isEmpty {
				loggerGlobal.error("Did not find any RTCClient to broadcast to?")
			}
			try await group.waitForAll()
		}
	}

	func send(
		response: P2P.RTCOutgoingMessage.Response,
		to connectionIdOfOrigin: PeerConnectionID
	) async throws {
		guard let anyConnection = peerConnections.values.first else {
			throw PeerConnectionDidCloseError()
		}
		let data = try JSONEncoder().encode(response)
		// print(data.prettyPrintedJSONString)
		try await anyConnection.sendData(data)
	}

	// MARK: - Private

	private func listenForPeerConnections() {
		connectionsTask = Task {
			for try await connectionResult in peerConnectionNegotiator.negotiationResults {
				do {
					try await onPeerConnectionCreated(connectionResult.get())
				} catch {
					// log error
					loggerGlobal.error("Failed to establish PeerConnection: \(error.localizedDescription)")
				}
			}
		}

		disconnectTask = Task {
			for await id in disconnectedPeerConnection {
				await removePeerConnection(id)
			}
		}
	}

	private func onPeerConnectionCreated(_ connection: PeerConnectionClient) async {
		await connection
			.receivedMessagesStream()
			.map { (messageResult: Result<DataChannelClient.AssembledMessage, Error>) in
				let route = P2P.RTCRoute(p2pLink: self.p2pLink, peerConnectionId: connection.id)
				return P2P.RTCIncomingMessage(
					result: decode(messageResult),
					route: .rtc(route),
					requiresOriginVerfication: false
				)
			}
			.subscribe(self.incomingMessagesContinuation)

		connection
			.iceConnectionStates
			.filter {
				$0 == .disconnected
			}
			.map { _ in connection.id }
			.subscribe(disconnectedPeerConnectionContinuation)

		connection
			.dataChannelReadyStates
			.filter {
				$0 == .closed
			}
			.map { _ in connection.id }
			.subscribe(disconnectedPeerConnectionContinuation)

		self.peerConnections[connection.id] = connection
	}
}

// FIXME: once we have merge together the separated message formats `Dapp` and `Ledger` in CAP21, clean up!
func decode(
	_ messageResult: Result<DataChannelClient.AssembledMessage, Error>
) -> Result<P2P.RTCMessageFromPeer, Error> {
	@Dependency(\.jsonDecoder) var jsonDecoderDep
	let jsonDecoder = jsonDecoderDep()

	return messageResult.flatMap { (message: DataChannelClient.AssembledMessage) in
		let jsonData = message.messageContent
		// print(jsonData.prettyPrintedJSONString)
		do {
			guard let jsonString = String(data: jsonData, encoding: .utf8) else {
				throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to convert data to UTF-8 string"))
			}
			return try .success(.request(.dapp(.init(jsonString: jsonString))))
		} catch let decodeRequestError {
			do {
				let response = try jsonDecoder.decode(
					P2P.RTCMessageFromPeer.Response.self,
					from: jsonData
				)
				return .success(
					.response(
						response
					)
				)

			} catch let decodeResponseError {
				loggerGlobal.error("Failed to decode as RTC request & response, request decoding failure: \(decodeRequestError)\n\nresponse decoding failure: \(decodeResponseError)")
				#if DEBUG
				loggerGlobal.critical("Decoding RadixConnect message, json:\n\n\(String(describing: jsonData.prettyPrintedJSONString))\n\n")
				#endif // DEBUG
				return .failure(decodeRequestError)
			}
		}
	}
}
