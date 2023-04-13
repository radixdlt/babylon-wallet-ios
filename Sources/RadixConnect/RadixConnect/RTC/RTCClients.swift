import AsyncExtensions
import CryptoKit
import Foundation
import Prelude
import SharedModels

// MARK: - RTCClients
/// Holds and manages all of added RTCClients
public actor RTCClients {
	public struct RTCClientDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"RTCClient did close, retry connecting the browser with the Wallet"
		}
	}

	// MARK: - Streams

	/// A **multicasted** async sequence for received messeage from ALL RTCClients.
	public func incomingMessages() async -> AnyAsyncSequence<P2P.RTCIncomingMessage> {
		incomingMessagesSubject.share().eraseToAnyAsyncSequence()
	}

	/// Incoming peer messages. This is the single channel for the received messages from all RTCClients
	private let incomingMessagesSubject: AsyncPassthroughSubject<P2P.RTCIncomingMessage> = .init()

	// MARK: - Config
	private let peerConnectionFactory: PeerConnectionFactory
	private let signalingServerBaseURL: URL

	// MARK: - Internal state
	private var clients: [RTCClient.ID: RTCClient] = [:]

	// MARK: - Initialisers

	init(peerConnectionFactory: PeerConnectionFactory,
	     signalingServerBaseURL: URL = SignalingClient.default)
	{
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
		_ linkPassword: ConnectionPassword,
		waitsForConnectionToBeEstablished: Bool = false
	) async throws {
		let client = try makeRTCClient(linkPassword)
		if waitsForConnectionToBeEstablished {
			try await client.waitForFirstConnection()
		}
		add(client)
	}

	/// Disconnect and remove the RTCClient for the given connection password
	/// - Parameter password: The connection password identifying the RTCClient
	public func disconnectAndRemoveClient(_ password: ConnectionPassword) async {
		await clients[password]?.cancel()
		clients.removeValue(forKey: password)
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
		guard let rtcClient = clients[origin.connectionId] else {
			throw RTCClientDidCloseError()
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
	public func sendRequest(
		_ request: P2P.RTCOutgoingMessage.Request,
		strategy sendStrategy: P2P.RTCOutgoingMessage.Request.SendStrategy
	) async throws {
		switch sendStrategy {
		case .broadcastToAllPeers:
			try await broadcastRequest(request)
		}
	}

	private func broadcastRequest(
		_ request: P2P.RTCOutgoingMessage.Request
	) async throws {
		try await withThrowingTaskGroup(of: Void.self) { group in
			for client in clients.values {
				guard !Task.isCancelled else {
					// We do not throw if cancelled, it is good we
					// manage to broadcast to SOME client (i.e. not ALL is required.)
					return
				}
				_ = group.addTaskUnlessCancelled {
					try await client.broadcast(request: request)
				}
			}
			try await group.waitForAll()
		}
	}

	// MARK: - Private

	func add(_ client: RTCClient) {
		client.incomingMessages.subscribe(incomingMessagesSubject)
		self.clients[client.id] = client
	}

	func makeRTCClient(_ password: ConnectionPassword) throws -> RTCClient {
		let signalingClient = try SignalingClient(
			password: password,
			baseURL: signalingServerBaseURL
		)
		let negotiator = PeerConnectionNegotiator(
			signalingClient: signalingClient,
			factory: peerConnectionFactory
		)
		return RTCClient(
			id: password,
			peerConnectionNegotiator: negotiator
		)
	}
}

// MARK: - RTCClient
actor RTCClient {
	let id: ID

	let incomingMessages: AsyncStream<P2P.RTCIncomingMessage>
	private let incomingMessagesContinuation: AsyncStream<P2P.RTCIncomingMessage>.Continuation
	private let peerConnectionNegotiator: PeerConnectionNegotiator
	private var peerConnections: [PeerConnectionClient.ID: PeerConnectionClient] = [:]
	private var connectionsTask: Task<Void, Error>?

	private let disconnectedPeerConnection: AsyncStream<PeerConnectionID>
	private let disconnectedPeerConnectionContinuation: AsyncStream<PeerConnectionID>.Continuation
	private var disconnectTask: Task<Void, Never>?

	init(
		id: ID,
		peerConnectionNegotiator: PeerConnectionNegotiator
	) {
		self.id = id
		self.peerConnectionNegotiator = peerConnectionNegotiator
		(incomingMessages, incomingMessagesContinuation) = AsyncStream.streamWithContinuation()

		(disconnectedPeerConnection, disconnectedPeerConnectionContinuation) = AsyncStream.streamWithContinuation()

		Task {
			await listenForPeerConnections()
		}
	}
}

extension RTCClient {
	typealias ID = ConnectionPassword
	public struct PeerConnectionDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"Peer Connection did close, retry the operation from dapp"
		}
	}
}

extension RTCClient {
	static var firstConnectionTimeout: Duration {
		.seconds(10)
	}

	/// Cancel all of the related operations allowing this RTCClient to be deallocated.
	func cancel() async {
		for peerConnection in peerConnections.values {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionNegotiator.cancel()
		incomingMessagesContinuation.finish()
		disconnectedPeerConnectionContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func waitForFirstConnection() async throws {
		_ = try await doAsync(withTimeout: Self.firstConnectionTimeout) {
			try await self.peerConnectionNegotiator.negotiationResults.first().get()
		}
	}

	func removePeerConnection(_ id: PeerConnectionID) async {
		await peerConnections[id]?.cancel()
		peerConnections.removeValue(forKey: id)
	}

	func broadcast(
		request: P2P.RTCOutgoingMessage.Request
	) async throws {
		let data = try JSONEncoder().encode(request)

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
			try await group.waitForAll()
		}
	}

	func send(
		response: P2P.RTCOutgoingMessage.Response,
		to connectionIdOfOrigin: PeerConnectionID
	) async throws {
		guard let client = peerConnections[connectionIdOfOrigin] else {
			throw PeerConnectionDidCloseError()
		}
		let data = try JSONEncoder().encode(response)
		try await client.sendData(data)
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
				let route = P2P.RTCRoute(connectionId: self.id, peerConnectionId: connection.id)
				return P2P.RTCIncomingMessage(
					result: decode(messageResult),
					route: route
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

		self.peerConnections[connection.id] = connection
	}
}

// FIXME: once we have merge together the separated message formats `Dapp` and `Ledger` in CAP21
// this ugliness will become less ugly!
func decode(
	_ messageResult: Result<DataChannelClient.AssembledMessage, Error>
) -> Result<P2P.RTCMessageFromPeer, Error> {
	let jsonDecoder = JSONDecoder()

	return messageResult.flatMap { (message: DataChannelClient.AssembledMessage) in

		let jsonData = message.messageContent

		do {
			let request = try jsonDecoder.decode(
				P2P.RTCMessageFromPeer.Request.self,
				from: jsonData
			)
			return .success(.request(request))
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
				return .failure(decodeRequestError)
			}
		}
	}
}
