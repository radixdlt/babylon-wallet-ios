import AsyncExtensions
import Foundation
import Prelude

// MARK: - WebSocketClient
protocol WebSocketClient: Sendable {
	var incommingMessages: AsyncThrowingStream<Data, Error> { get }
	func send(message: Data) async throws
}

enum ClientSource: String, Sendable, Codable, Equatable {
        case wallet
        case `extension`
}

// MARK: - SignalingClient
struct SignalingClient {
	// MARK: - Configuration
	private let encryptionKey: EncryptionKey
	private let jsonDecoder: JSONDecoder
	private let jsonEncoder: JSONEncoder
	private let connectionID: SignalingServerConnectionID
	private let idBuilder: @Sendable () -> RequestID
	private let webSocketClient: WebSocketClient
	private let clientSource: ClientSource

	// MARK: - Streams
	private let incommingMessages: AnyAsyncSequence<IncommingMessage>
	private let incommingSignalingServerMessagges: AnyAsyncSequence<IncommingMessage.FromSignalingServer>
	private let incommingRemoteClientMessagges: AnyAsyncSequence<RemoteData>

	let onICECanddiate: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.ICECandidate>>
	let onOffer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Offer>>
	let onAnswer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Answer>>
	let onRemoteClientState: AnyAsyncSequence<IncommingMessage.FromSignalingServer.Notification>

	// MARK: - Initializer

	init(encryptionKey: EncryptionKey,
	     webSocketClient: WebSocketClient,
	     connectionID: SignalingServerConnectionID,
	     idBuilder: @Sendable @escaping () -> RequestID = { .init(UUID().uuidString) },
	     jsonDecoder: JSONDecoder = .init(),
	     jsonEncoder: JSONEncoder = .init(),
             clientSource: ClientSource = .wallet)
	{
		self.encryptionKey = encryptionKey
		self.webSocketClient = webSocketClient
		self.connectionID = connectionID
		self.idBuilder = idBuilder
		self.jsonEncoder = jsonEncoder
		self.jsonDecoder = jsonDecoder
		self.clientSource = clientSource
                self.jsonDecoder.userInfo[.clientMessageEncryptonKey] = encryptionKey
                self.jsonEncoder.userInfo[.clientMessageEncryptonKey] = encryptionKey

		self.incommingMessages = webSocketClient
			.incommingMessages
			.eraseToAnyAsyncSequence()
			.mapSkippingError {
				try jsonDecoder.decode(IncommingMessage.self, from: $0)
			} logError: { error in
				loggerGlobal.info("Failed to decode incomming Message - \(error)")
			}
			.share()
			.eraseToAnyAsyncSequence()

		self.incommingRemoteClientMessagges = self.incommingMessages
			.compactMap(\.fromRemoteClient)
			.eraseToAnyAsyncSequence()

		self.incommingSignalingServerMessagges = self.incommingMessages
			.compactMap(\.fromSignalingServer)
			.eraseToAnyAsyncSequence()

		self.onOffer = self.incommingRemoteClientMessagges
			.compactMap(\.offer)
			.logInfo("Received Offer from remote client: %@")
			.share()
			.eraseToAnyAsyncSequence()

		self.onAnswer = self.incommingRemoteClientMessagges
			.compactMap(\.answer)
			.logInfo("Received Answer from remote client: %@")
			.share()
			.eraseToAnyAsyncSequence()

		self.onICECanddiate = self.incommingRemoteClientMessagges
                        .compactMap(\.iceCandidate)
			.logInfo("Received ICECandidate from remote client: %@")
			.share()
			.eraseToAnyAsyncSequence()

		self.onRemoteClientState = self.incommingSignalingServerMessagges
			.compactMap(\.notification)
			.logInfo("Received Notification from Signaling Server: %@")
			.share()
			.eraseToAnyAsyncSequence()
	}

        public func sendToRemote(_ primitive: IdentifiedPrimitive<RTCPrimitive>) async throws {
                let message = ClientMessage(
                        requestId: idBuilder(),
                        targetClientId: primitive.id,
                        primitive: primitive.content,
                        connectionId: connectionID,
                        source: clientSource)
                let encodedMessage = try jsonEncoder.encode(message)
                try await webSocketClient.send(message: encodedMessage)
                try await waitForRequestAck(message.requestId)
        }
        
	public func sendToRemote(message: ClientMessage) async throws {
		let encodedMessage = try jsonEncoder.encode(message)
		try await webSocketClient.send(message: encodedMessage)
                try await waitForRequestAck(message.requestId)
	}

	private func waitForRequestAck(_ requestId: RequestID) async throws {
		try await self.incommingSignalingServerMessagges
			.compactMap(\.responseForRequest)
			.compactMap { incoming in
				try incoming.resultOfRequest(id: requestId)?.get()
			}
			.first { true }
	}
}
