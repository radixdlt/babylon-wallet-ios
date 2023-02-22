import AsyncExtensions
import Foundation

// MARK: - RTCClients

public struct RTCIncommingMessage: Sendable {
        public let connectionId: SignalingServerConnectionID
        public let content: PeerConnectionMessage

        public struct PeerConnectionMessage: Sendable {
                public let peerConnectionId: PeerConnectionId
                public let content: Result<DataChannelAssembledMessage, Error>
        }
}

public struct RTCOutgoingMessage: Sendable {
        public let connectionId: SignalingServerConnectionID
        public let content: PeerConnectionMessage

        public struct PeerConnectionMessage: Sendable {
                public let peerConnectionId: PeerConnectionId
                public let content: Data

                init(peerConnectionId: PeerConnectionId, content: Data) {
                        self.peerConnectionId = peerConnectionId
                        self.content = content
                }
        }

        init(connectionId: SignalingServerConnectionID, content: PeerConnectionMessage) {
                self.connectionId = connectionId
                self.content = content
        }
}

/// Meant to hold all of the created RTCClients
public actor RTCClients {
        public let onIncommingMessage: AsyncStream<RTCIncommingMessage>

	private var clients: [RTCClient] = []
	private let onIncommingMessageContinuation: AsyncStream<RTCIncommingMessage>.Continuation!
	private let peerConnectionFactory: PeerConnectionFactory

        init(peerConnectionFactory: PeerConnectionFactory) {
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<RTCIncommingMessage>.streamWithContinuation()
		self.peerConnectionFactory = peerConnectionFactory
	}

	public func add(_ connectionId: SignalingServerConnectionID) async throws {
                let connectionURL = try signalingServerURL(connectionID: connectionId, source: .wallet)
		let webSocket = AsyncWebSocket(url: connectionURL)
                let encryptionKey = try EncryptionKey(.init(data: connectionId.data.data))

		let signalingClient = SignalingClient(encryptionKey: encryptionKey, webSocketClient: webSocket, connectionID: connectionId)
		let builder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)
		let client = RTCClient(id: connectionId, peerConnectionBuilder: builder)
                await client.listenForPeerConnections()

                client.onIncommingMessage
                        .map { RTCIncommingMessage(connectionId: connectionId, content: $0) }
                        .susbscribe(onIncommingMessageContinuation)
		self.clients.append(client)
	}

	public func remove(_ connectionId: SignalingServerConnectionID) {
		clients.removeAll(where: { $0.id == connectionId })
	}

        public func sendMessage(_ message: RTCOutgoingMessage) async throws {
                guard let rtcClient = clients.first(where: { $0.id == message.connectionId }) else {
                        fatalError()
                }

                try await rtcClient.sendMessage(message.content)
        }
}

// MARK: - RTCClient

/// Meant to hold all of the peerConnections for the given SignalingServerConnectionID
actor RTCClient {
	let id: SignalingServerConnectionID
	private let peerConnectionBuilder: PeerConnectionBuilder
	private var peerConnections: [PeerConnectionClient] = []

        let onIncommingMessage: AsyncStream<RTCIncommingMessage.PeerConnectionMessage>
        private let onIncommingMessageContinuation: AsyncStream<RTCIncommingMessage.PeerConnectionMessage>.Continuation!
	private var connectionsTask: Task<Void, Never>?

	init(id: SignalingServerConnectionID,
	     peerConnectionBuilder: PeerConnectionBuilder)
	{
		self.id = id
		self.peerConnectionBuilder = peerConnectionBuilder
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<RTCIncommingMessage.PeerConnectionMessage>.streamWithContinuation()
	}

	deinit {
		connectionsTask?.cancel()
	}

	func listenForPeerConnections() {
		connectionsTask = Task {
			for await connectionResult in peerConnectionBuilder.peerConnections {
				do {
					let connection = try connectionResult.get()
                                        await connection
                                                .receivedMessagesStream()
                                                .map { RTCIncommingMessage.PeerConnectionMessage(peerConnectionId: connection.id, content: $0) }
                                                .susbscribe(self.onIncommingMessageContinuation)
					self.peerConnections.append(connection)
				} catch {
					// log error
				}
			}
		}
	}

        func sendMessage(_ message: RTCOutgoingMessage.PeerConnectionMessage) async throws {
                guard let client = peerConnections.first(where: { $0.id == message.peerConnectionId }) else {
                        fatalError()
                }

                try await client.sendData(message.content)
        }
}

public extension URL {
	static let defaultBaseForSignalingServer = Self(string: "wss://signaling-server-betanet.radixdlt.com")!
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
	source: ClientSource = .wallet
) throws -> URL {
	let target: ClientSource = source == .wallet ? .extension : .wallet

	let url = URL.defaultBaseForSignalingServer.appendingPathComponent(
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
		)
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
