import AsyncExtensions
import Foundation

// MARK: - RTCClients

/// Meant to hold all of the created RTCClients
actor RTCClients {
        struct IncommingMessage {
                let connectionId: SignalingServerConnectionID
                let content: RTCClient.IncommingMessage
        }

        struct OutgoingMessage {
                let connectionId: SignalingServerConnectionID
                let content: RTCClient.OutgoingMessage
        }

	private var clients: [RTCClient] = []

	let onIncommingMessage: AsyncStream<IncommingMessage>
	let onIncommingMessageContinuation: AsyncStream<IncommingMessage>.Continuation!

	let peerConnectionFactory: PeerConnectionFactory

	private init(peerConnectionFactory: PeerConnectionFactory) {
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<IncommingMessage>.streamWithContinuation()
		self.peerConnectionFactory = peerConnectionFactory
	}

	func add(_ connectionId: SignalingServerConnectionID) async throws {
                let ownClientId = ClientID(rawValue: UUID().uuidString)
                let connectionURL = try signalingServerURL(connectionID: connectionId, source: .wallet, ownClientId: ownClientId)
		let webSocket = AsyncWebSocket(url: connectionURL)
                let encryptionKey = try EncryptionKey(.init(data: connectionId.data.data))

		let signalingClient = SignalingClient(encryptionKey: encryptionKey, webSocketClient: webSocket, connectionID: connectionId, ownClientId: ownClientId)
		let builder = PeerConnectionBuilder(signalingServerClient: signalingClient, factory: peerConnectionFactory)
		let client = RTCClient(id: connectionId, peerConnectionBuilder: builder)
                await client.listenForPeerConnections()

                client.onIncommingMessage
                        .map { IncommingMessage(connectionId: connectionId, content: $0) }
                        .susbscribe(onIncommingMessageContinuation)
		self.clients.append(client)
	}

	func remove(_ connectionId: SignalingServerConnectionID) {
		clients.removeAll(where: { $0.id == connectionId })
	}

        func sendMessage(_ message: OutgoingMessage) async throws {
                guard let rtcClient = clients.first(where: { $0.id == message.connectionId }) else {
                        fatalError()
                }

                try await rtcClient.sendMessage(message.content)
        }
}

// MARK: - RTCClient

/// Meant to hold all of the peerConnections for the given SignalingServerConnectionID
actor RTCClient {
        struct IncommingMessage {
                let peerConnectionId: PeerConnectionClient.ID
                let content: Result<DataChannelAssembledMessage, Error>
        }

        struct OutgoingMessage {
                let peerConnectionId: PeerConnectionClient.ID
                let content: Data
        }

	let id: SignalingServerConnectionID
	private let peerConnectionBuilder: PeerConnectionBuilder
	private var peerConnections: [PeerConnectionClient] = []

	let onIncommingMessage: AsyncStream<IncommingMessage>
	private let onIncommingMessageContinuation: AsyncStream<IncommingMessage>.Continuation!
	private var connectionsTask: Task<Void, Never>?

	init(id: SignalingServerConnectionID,
	     peerConnectionBuilder: PeerConnectionBuilder)
	{
		self.id = id
		self.peerConnectionBuilder = peerConnectionBuilder
		(onIncommingMessage, onIncommingMessageContinuation) = AsyncStream<IncommingMessage>.streamWithContinuation()
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
                                                .map { IncommingMessage(peerConnectionId: connection.id, content: $0) }
                                                .susbscribe(self.onIncommingMessageContinuation)
					self.peerConnections.append(connection)
				} catch {
					// log error
				}
			}
		}
	}

        func sendMessage(_ message: OutgoingMessage) async throws {
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
        case target, source, client_id
}

func signalingServerURL(
	connectionID: SignalingServerConnectionID,
	source: ClientMessage.Source = .wallet,
        ownClientId: ClientID
) throws -> URL {
	let target: ClientMessage.Source = source == .wallet ? .extension : .wallet

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
		),
                .init(
                        name: QueryParameterName.client_id.rawValue,
                        value: ownClientId.rawValue
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
