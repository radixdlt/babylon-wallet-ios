import AsyncExtensions
import CryptoKit
import Foundation
import SharedModels

// MARK: - RTCClients

public typealias RTCIncommingMessageResult = RTCIncommingMessage<Result<P2P.FromDapp.WalletInteraction, Error>>
public typealias RTCIncommingWalletInteraction = RTCIncommingMessage<P2P.FromDapp.WalletInteraction>

// MARK: - RTCIncommingMessage
public struct RTCIncommingMessage<PeerConnectionContent: Sendable>: Sendable {
	public let connectionId: ConnectionPassword
	public let content: PeerConnectionMessage

	public struct PeerConnectionMessage: Sendable {
		public let peerConnectionId: PeerConnectionId
		public let content: PeerConnectionContent
	}
}

extension RTCIncommingMessage where PeerConnectionContent == Result<P2P.FromDapp.WalletInteraction, Error> {
	public func unwrapResult() throws -> RTCIncommingWalletInteraction {
		try .init(connectionId: connectionId,
		          content: .init(peerConnectionId: content.peerConnectionId, content: content.content.get()))
	}
}

// MARK: - RTCIncommingMessage.PeerConnectionMessage + Hashable, Equatable
// extension RTCIncommingMessage.PeerConnectionMessage: Equatable where PeerConnectionContent: Hashable & Equatable {}
extension RTCIncommingMessage.PeerConnectionMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}

// MARK: - RTCIncommingMessage + Hashable, Equatable
extension RTCIncommingMessage: Hashable, Equatable where PeerConnectionContent: Hashable & Equatable {}

extension RTCIncommingMessage {
	public func toOutgoingMessage(_ response: P2P.ToDapp.WalletInteractionResponse) -> RTCOutgoingMessage {
		.init(connectionId: connectionId,
		      content: .init(peerConnectionId: content.peerConnectionId,
		                     content: response))
	}
}

// MARK: - RTCOutgoingMessage
public struct RTCOutgoingMessage: Sendable, Hashable {
	public let connectionId: ConnectionPassword
	public let content: PeerConnectionMessage

	public struct PeerConnectionMessage: Sendable, Hashable {
		public let peerConnectionId: PeerConnectionId
		public let content: P2P.ToDapp.WalletInteractionResponse

		public init(peerConnectionId: PeerConnectionId, content: P2P.ToDapp.WalletInteractionResponse) {
			self.peerConnectionId = peerConnectionId
			self.content = content
		}
	}

	public init(connectionId: ConnectionPassword, content: PeerConnectionMessage) {
		self.connectionId = connectionId
		self.content = content
	}
}

// MARK: - RTCClients
/// Meant to hold all of the created RTCClients
public actor RTCClients {
	public lazy var incommingMessages: AnyAsyncSequence<RTCIncommingMessageResult> = onIncommingMessage.eraseToAnyAsyncSequence().share().eraseToAnyAsyncSequence()

	private let onIncommingMessage: AsyncStream<RTCIncommingMessageResult>

	private(set) var clients: [RTCClient] = []
	private let onIncommingMessageContinuation: AsyncStream<RTCIncommingMessageResult>.Continuation!
	private let peerConnectionFactory: PeerConnectionFactory
	private let signalingServerBaseURL: URL

	public init(signalingServerBaseURL: URL = .prodSignalingServer) {
		self.init(peerConnectionFactory: WebRTCFactory(), signalingServerBaseURL: signalingServerBaseURL)
	}

	init(peerConnectionFactory: PeerConnectionFactory = WebRTCFactory(), signalingServerBaseURL: URL = .prodSignalingServer) {
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<RTCIncommingMessageResult>.streamWithContinuation()
		self.peerConnectionFactory = peerConnectionFactory
		self.signalingServerBaseURL = signalingServerBaseURL
	}

	public func add(_ password: ConnectionPassword) async throws {
		let signalingClient = try SignalingClient(password: password, source: .wallet, baseURL: signalingServerBaseURL)
		let builder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)
		let client = RTCClient(id: password, peerConnectionBuilder: builder)
		await client.listenForPeerConnections()

		client.onIncommingMessage
			.map { RTCIncommingMessage(connectionId: password, content: $0) }
			.susbscribe(onIncommingMessageContinuation)
		self.clients.append(client)
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

	public func sendMessage(_ message: RTCOutgoingMessage) async throws {
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

	let onIncommingMessage: AsyncStream<RTCIncommingMessageResult.PeerConnectionMessage>
	private let onIncommingMessageContinuation: AsyncStream<RTCIncommingMessageResult.PeerConnectionMessage>.Continuation!
	private var connectionsTask: Task<Void, Never>?

	private let onPeerConnectionDisconnected: AsyncStream<PeerConnectionId>
	private let onPeerConnectionDisconnectedContinuation: AsyncStream<PeerConnectionId>.Continuation!

	private var disconnectTask: Task<Void, Never>?

	init(id: ConnectionPassword,
	     peerConnectionBuilder: PeerConnectionBuilder)
	{
		self.id = id
		self.peerConnectionBuilder = peerConnectionBuilder
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<RTCIncommingMessageResult.PeerConnectionMessage>.streamWithContinuation()
		(onPeerConnectionDisconnected, onPeerConnectionDisconnectedContinuation) = AsyncStream<PeerConnectionId>.streamWithContinuation()
	}

	func cancel() async {
		for peerConnection in peerConnections {
			await peerConnection.cancel()
		}
		peerConnections.removeAll()
		peerConnectionBuilder.cancel()
		onIncommingMessageContinuation.finish()
		onPeerConnectionDisconnectedContinuation.finish()
		connectionsTask?.cancel()
		disconnectTask?.cancel()
	}

	func listenForPeerConnections() {
		connectionsTask = Task {
			for await connectionResult in peerConnectionBuilder.peerConnections {
				do {
					let connection = try connectionResult.get()
					await connection
						.receivedMessagesStream()
						.map { messageResult in
							let interaction = messageResult.flatMap { message in
								.init { try JSONDecoder().decode(P2P.FromDapp.WalletInteraction.self, from: message.messageContent) }
							}
							return RTCIncommingMessage.PeerConnectionMessage(peerConnectionId: connection.id,
							                                                 content: interaction)
						}
						.susbscribe(self.onIncommingMessageContinuation)
					connection
						.onIceConnectionState
						.filter {
							$0 == .disconnected
						}
						.map { _ in connection.id }
						.susbscribe(onPeerConnectionDisconnectedContinuation)
					self.peerConnections.append(connection)
				} catch {
					// log error
				}
			}
		}

		disconnectTask = Task {
			for await id in onPeerConnectionDisconnected {
				removePeerConnection(id)
			}
		}
	}

	func removePeerConnection(_ id: PeerConnectionId) {
		print("==== Removing Peer connection")
		peerConnections.removeAll(where: { $0.id == id })
	}

	func sendMessage(_ message: RTCOutgoingMessage.PeerConnectionMessage) async throws {
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
//
	//        var localizedDescription: String {
	//                "Peer Connection did close, retry the operation from Dapp"
	//        }
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
