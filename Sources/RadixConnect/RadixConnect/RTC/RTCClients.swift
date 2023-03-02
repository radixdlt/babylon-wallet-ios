import AsyncExtensions
import CryptoKit
import Foundation
import SharedModels

// MARK: - RTCClients
/// Meant to hold all of the created RTCClients
public actor RTCClients {
        public let incommingMessages: AsyncStream<P2P.RTCIncommingMessageResult>

	private(set) var clients: [RTCClient] = []
        private let incommingMessagesContinuation: AsyncStream<P2P.RTCIncommingMessageResult>.Continuation!
	private let peerConnectionFactory: PeerConnectionFactory
	private let signalingServerBaseURL: URL

	public init(signalingServerBaseURL: URL = .prodSignalingServer) {
		self.init(peerConnectionFactory: WebRTCFactory(), signalingServerBaseURL: signalingServerBaseURL)
	}

	init(peerConnectionFactory: PeerConnectionFactory = WebRTCFactory(), signalingServerBaseURL: URL = .prodSignalingServer) {
		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()
		self.peerConnectionFactory = peerConnectionFactory
		self.signalingServerBaseURL = signalingServerBaseURL
	}

	public func add(_ password: ConnectionPassword) async throws {
		let client = try await makeRTCClient(password)
		add(client)
	}

	public func addNewConnection(_ password: ConnectionPassword) async throws {
		let client = try await makeRTCClient(password)
		try await client.waitForFirstConnection()
		add(client)
	}

	func add(_ client: RTCClient) {
		client.incommingMessages.susbscribe(incommingMessagesContinuation)
		self.clients.append(client)
	}

	private func makeRTCClient(_ password: ConnectionPassword) async throws -> RTCClient {
		let signalingClient = try SignalingClient(password: password, source: .wallet, baseURL: signalingServerBaseURL)
		let builder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)
		let client = RTCClient(id: password, peerConnectionBuilder: builder)

		await client.listenForPeerConnections()

		return client
	}

	public func remove(_ connectionId: ConnectionPassword) async {
		await clients.first(where: { $0.id == connectionId })?.cancel()
		clients.removeAll(where: { $0.id == connectionId })
	}

	public func removeAll() async {
		for client in clients {
			await client.cancel()
		}
		clients.removeAll()
	}

        public func sendMessage(_ message: P2P.RTCOutgoingMessage) async throws {
		guard let rtcClient = clients.first(where: { $0.id == message.connectionId }) else {
			fatalError()
		}

		try await rtcClient.sendMessage(message.content)
	}
}

extension SignalingClient {
	init(password: ConnectionPassword, source: ClientSource, baseURL: URL) throws {
		let connectionId = try SignalingServerConnectionID(.init(.init(data: Data(SHA256.hash(data: password.data.data)))))
		let connectionURL = try signalingServerURL(connectionID: connectionId, source: source, baseURL: baseURL)
		let webSocket = AsyncWebSocket(url: connectionURL)
		let encryptionKey = try EncryptionKey(.init(data: password.data.data))

		self.init(encryptionKey: encryptionKey, webSocketClient: webSocket, connectionID: connectionId, clientSource: source)
	}
}

// MARK: - RTCClient
/// Meant to hold all of the peerConnections for the given SignalingServerConnectionID
actor RTCClient {
	let id: ConnectionPassword
	private let peerConnectionBuilder: PeerConnectionBuilder
	private(set) var peerConnections: [PeerConnectionClient] = []

        let incommingMessages: AsyncStream<P2P.RTCIncommingMessageResult>
        private let incommingMessagesContinuation: AsyncStream<P2P.RTCIncommingMessageResult>.Continuation!
	private var connectionsTask: Task<Void, Error>?

	private let onPeerConnectionDisconnected: AsyncStream<PeerConnectionId>
	private let onPeerConnectionDisconnectedContinuation: AsyncStream<PeerConnectionId>.Continuation!

	private var disconnectTask: Task<Void, Never>?

	init(id: ConnectionPassword,
	     peerConnectionBuilder: PeerConnectionBuilder)
	{
		self.id = id
		self.peerConnectionBuilder = peerConnectionBuilder
		(incommingMessages, incommingMessagesContinuation) = AsyncStream.streamWithContinuation()
		(onPeerConnectionDisconnected, onPeerConnectionDisconnectedContinuation) = AsyncStream<PeerConnectionId>.streamWithContinuation()
	}

	func waitForFirstConnection() async throws {
		_ = try await peerConnectionBuilder.peerConnections.prefix(1).collect().first!.get()
	}

	func cancel() async {
		for peerConnection in peerConnections {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionBuilder.cancel()
		incommingMessagesContinuation.finish()
		onPeerConnectionDisconnectedContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func listenForPeerConnections() {
		connectionsTask = Task {
			for try await connectionResult in peerConnectionBuilder.peerConnections {
				do {
					try await onPeerConnectionCreated(connectionResult.get())
				} catch {
					// log error
				}
			}
		}

		disconnectTask = Task {
			for await id in onPeerConnectionDisconnected {
				await removePeerConnection(id)
			}
		}
	}

	func onPeerConnectionCreated(_ connection: PeerConnectionClient) async {
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
			.onIceConnectionState
			.filter {
				$0 == .disconnected
			}
			.map { _ in connection.id }
			.susbscribe(onPeerConnectionDisconnectedContinuation)
		self.peerConnections.append(connection)
	}

	func removePeerConnection(_ id: PeerConnectionId) async {
		print("Removing peer connection for id: \(id)")
		await peerConnections.first(where: { $0.id == id })?.cancel()
		peerConnections.removeAll(where: { $0.id == id })
	}

        func sendMessage(_ message: P2P.RTCOutgoingMessage.PeerConnectionMessage) async throws {
		guard let client = peerConnections.first(where: { $0.id == message.peerConnectionId }) else {
			throw PeerConnectionDidCloseError()
		}
		let data = try JSONEncoder().encode(message.content)
		try await client.sendData(data)
	}
}

// MARK: - PeerConnectionDidCloseError
public struct PeerConnectionDidCloseError: Error, LocalizedError {
	public var errorDescription: String? {
		"Peer Connection did close, retry the operation from dapp"
	}
}

public extension URL {
	static let prodSignalingServer = Self(string: "wss://signaling-server-betanet.radixdlt.com")!
	static let devSignalingServer = Self(string: "wss://signaling-server-dev.rdx-works-main.extratools.works")!
}

// MARK: - FailedToCreateSignalingServerURL
struct FailedToCreateSignalingServerURL: LocalizedError {
	var errorDescription: String? {
		"Failed to create url"
	}
}

// MARK: - QueryParameterName
enum QueryParameterName: String {
	case target, source
}

func signalingServerURL(
	connectionID: SignalingServerConnectionID,
	source: ClientSource = .wallet,
	baseURL: URL = .prodSignalingServer
) throws -> URL {
	let target: ClientSource = source == .wallet ? .extension : .wallet

	let url = baseURL.appendingPathComponent(
		connectionID.hex
	)

	guard
		var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
	else {
		throw FailedToCreateSignalingServerURL()
	}

	urlComponents.queryItems = [
		.init(
			name: QueryParameterName.target.rawValue,
			value: target.rawValue
		),
		.init(
			name: QueryParameterName.source.rawValue,
			value: source.rawValue
		),
	]

	guard let serverURL = urlComponents.url else {
		throw FailedToCreateSignalingServerURL()
	}

	return serverURL
}

extension SignalingServerConnectionID {
	var hex: String {
		self.rawValue.data.hex()
	}
}
