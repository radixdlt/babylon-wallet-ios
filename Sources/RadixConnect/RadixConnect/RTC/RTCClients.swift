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

	/// Incoming peer messages. This is the single channel for the received messages from all RTCClients
	public let IncomingMessages: AsyncStream<P2P.RTCIncomingMessageResult>
	private let IncomingMessagesContinuation: AsyncStream<P2P.RTCIncomingMessageResult>.Continuation

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
		(IncomingMessages, IncomingMessagesContinuation) = AsyncStream.streamWithContinuation()
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

	public func connect(_ linkPassword: ConnectionPassword, waitsForConnectionToBeEstablished: Bool = false) async throws {
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

	/// Sends the given message using the specific RTCClient.
	/// If the target RTCClient did close, an error will be thrown
	///
	/// - Parameter message: The message to be sent
	public func sendMessage(_ message: P2P.RTCOutgoingMessage) async throws {
		guard let rtcClient = clients[message.connectionId] else {
			throw RTCClientDidCloseError()
		}

		try await rtcClient.sendMessage(message.peerMessage)
	}

	// MARK: - Private

	private func add(_ client: RTCClient) {
		client.IncomingMessages.susbscribe(IncomingMessagesContinuation)
		self.clients[client.id] = client
	}

	private func makeRTCClient(_ password: ConnectionPassword) throws -> RTCClient {
		let signalingClient = try SignalingClient(
			password: password,
			source: .wallet,
			baseURL: signalingServerBaseURL
		)
		let negotiator = PeerConnectionNegotiator(
			signalingServerClient: signalingClient,
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
	/// Incoming peer messages. This is the single channel for the received messages from all PeerConnections.
	let IncomingMessages: AsyncStream<P2P.RTCIncomingMessageResult>

	private let IncomingMessagesContinuation: AsyncStream<P2P.RTCIncomingMessageResult>.Continuation
	private let peerConnectionNegotiator: PeerConnectionNegotiator
	private var peerConnections: [PeerConnectionClient.ID: PeerConnectionClient] = [:]
	private var connectionsTask: Task<Void, Error>?

	private let disconnectedPeerConnection: AsyncStream<PeerConnectionID>
	private let disconnectedPeerConnectionContinuation: AsyncStream<PeerConnectionID>.Continuation
	private var disconnectTask: Task<Void, Never>?

	init(id: ID,
	     peerConnectionNegotiator: PeerConnectionNegotiator)
	{
		self.id = id
		self.peerConnectionNegotiator = peerConnectionNegotiator
		(IncomingMessages, IncomingMessagesContinuation) = AsyncStream.streamWithContinuation()
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
	/// Cancel all of the related operations allowing this RTCClient to be deallocated.
	func cancel() async {
		for peerConnection in peerConnections.values {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionNegotiator.cancel()
		IncomingMessagesContinuation.finish()
		disconnectedPeerConnectionContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func waitForFirstConnection() async throws {
		_ = try await peerConnectionNegotiator.negotiationResults.first().get()
	}

	func removePeerConnection(_ id: PeerConnectionID) async {
		await peerConnections[id]?.cancel()
		peerConnections.removeValue(forKey: id)
	}

	func sendMessage(_ message: P2P.RTCOutgoingMessage.PeerConnectionMessage) async throws {
		guard let client = peerConnections[message.peerConnectionId] else {
			throw PeerConnectionDidCloseError()
		}
		let data = try JSONEncoder().encode(message.content)
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
			.map { messageResult in
				let interaction = messageResult.flatMap { message in
					.init { try JSONDecoder().decode(P2P.FromDapp.WalletInteraction.self, from: message.messageContent) }
				}
				return P2P.RTCIncomingMessage.PeerConnectionMessage(peerConnectionId: connection.id,
				                                                    content: interaction)
			}.map {
				P2P.RTCIncomingMessageResult(connectionId: self.id, content: $0)
			}
			.susbscribe(IncomingMessagesContinuation)

		connection
			.iceConnectionStates
			.filter {
				$0 == .disconnected
			}
			.map { _ in connection.id }
			.susbscribe(disconnectedPeerConnectionContinuation)

		self.peerConnections[connection.id] = connection
	}
}
