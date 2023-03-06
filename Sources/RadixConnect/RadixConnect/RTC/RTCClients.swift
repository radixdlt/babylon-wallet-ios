import AsyncExtensions
import CryptoKit
import Foundation
import SharedModels

/// Holds and manages all of added RTCClients
public actor RTCClients {
	public struct RTCClientDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"RTCClient did close, retry connecting the browser with the Wallet"
		}
	}

	// MARK: - Streams

	/// Incomming peer messages. This is the single channel for the received messages from all RTCClients
	public let incommingMessages: AsyncStream<P2P.RTCIncommingMessageResult>
	private let incommingMessagesContinuation: AsyncStream<P2P.RTCIncommingMessageResult>.Continuation!

	// MARK: - Config
	private let peerConnectionFactory: PeerConnectionFactory
	private let signalingServerBaseURL: URL

	// MARK: - Internal state
        private var clients: [RTCClient.ID: RTCClient] = [:]

	// MARK: - Initialisers

	public init() {
		self.init(peerConnectionFactory: WebRTCFactory(), signalingServerBaseURL: SignalingClient.prodSignalingServer)
	}

	init(peerConnectionFactory: PeerConnectionFactory,
	     signalingServerBaseURL: URL)
	{
		self.peerConnectionFactory = peerConnectionFactory
		self.signalingServerBaseURL = signalingServerBaseURL
		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()
	}

	// MARK: - Public API

	/// Add an existng RTCClient for the given password
	/// - Parameter password: The connection password used to previously connect the RTCClient
	public func addExistingClient(_ password: ConnectionPassword) throws {
		let client = try makeRTCClient(password)
		add(client)
	}

	/// Adds a new RTCClient for the given password.
	/// In comparison with `addExistingClient`, this function will await for the first connection
	/// to be established. If establishing the connection fails, the RTCClient will not be added
	/// and a specific error will be thrown
	///
	/// - Parameter password: The connection password to be used to creat the new RTCClient
	public func addNewClient(_ password: ConnectionPassword) async throws {
		let client = try makeRTCClient(password)
		try await client.waitForFirstConnection()
		add(client)
	}

	/// Remove the RTCClient for the given connection password
	/// - Parameter password: The connection password identifying the RTCClient
	public func removeClient(_ password: ConnectionPassword) async {
                await clients[password]?.cancel()
                clients.removeValue(forKey: password)
	}

	/// Remove all RTCClients
	public func removeAll() async {
                for id in clients.keys {
                        await removeClient(id)
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

		try await rtcClient.sendMessage(message.content)
	}

	// MARK: - Private

	private func add(_ client: RTCClient) {
		client.incommingMessages.susbscribe(incommingMessagesContinuation)
                self.clients[client.id] = client
	}

	private func makeRTCClient(_ password: ConnectionPassword) throws -> RTCClient {
		let signalingClient = try SignalingClient(password: password, source: .wallet, baseURL: signalingServerBaseURL)
		let builder = PeerConnectionNegotiator(signalingServerClient: signalingClient, factory: peerConnectionFactory)
		return RTCClient(id: password, peerConnectionBuilder: builder)
	}
}

// MARK: - RTCClient
actor RTCClient {
        typealias ID = ConnectionPassword

	// MARK: - PeerConnectionDidCloseError
	public struct PeerConnectionDidCloseError: Error, LocalizedError {
		public var errorDescription: String? {
			"Peer Connection did close, retry the operation from dapp"
		}
	}

	let id: ID
	/// Incomming peer messages. This is the single channel for the received messages from all PeerConnections.
	let incommingMessages: AsyncStream<P2P.RTCIncommingMessageResult>

	private let incommingMessagesContinuation: AsyncStream<P2P.RTCIncommingMessageResult>.Continuation!
	private let peerConnectionBuilder: PeerConnectionNegotiator
        private var peerConnections: [PeerConnectionClient.ID: PeerConnectionClient] = [:]
	private var connectionsTask: Task<Void, Error>?

	private let disconnectedPeerConnection: AsyncStream<PeerConnectionID>
	private let disconnectedPeerConnectionContinuation: AsyncStream<PeerConnectionID>.Continuation!
	private var disconnectTask: Task<Void, Never>?

	init(id: ID,
	     peerConnectionBuilder: PeerConnectionNegotiator)
	{
		self.id = id
		self.peerConnectionBuilder = peerConnectionBuilder
		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()
		(disconnectedPeerConnection, disconnectedPeerConnectionContinuation) = AsyncStream<PeerConnectionID>.streamWithContinuation()

		Task {
			await listenForPeerConnections()
		}
	}

	/// Cancel all of the related operations allowing this RTCClient to be deallocated.
	func cancel() async {
                for peerConnection in peerConnections.values {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionBuilder.cancel()
		incommingMessagesContinuation.finish()
		disconnectedPeerConnectionContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func waitForFirstConnection() async throws {
		_ = try await peerConnectionBuilder.negotiationResults.prefix(1).collect().first!.get()
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
			for try await connectionResult in peerConnectionBuilder.negotiationResults {
				do {
					try await onPeerConnectionCreated(connectionResult.get())
				} catch {
					// log error
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
				return P2P.RTCIncommingMessage.PeerConnectionMessage(peerConnectionId: connection.id,
				                                                     content: interaction)
			}.map {
				P2P.RTCIncommingMessageResult(connectionId: self.id, content: $0)
			}
			.susbscribe(incommingMessagesContinuation)

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
