import AsyncExtensions
import Foundation
import Prelude

// MARK: - WebSocketClient
protocol WebSocketClient: Sendable {
	var incomingMessageStream: AsyncThrowingStream<Data, Error> { get }
	func send(message: Data) async throws
}

// MARK: - AnyAsyncIterator + Sendable
extension AnyAsyncIterator: @unchecked Sendable where Self.Element: Sendable {}

// MARK: - AnyAsyncSequence + Sendable
extension AnyAsyncSequence: @unchecked Sendable where Self.AsyncIterator: Sendable {}

// MARK: - SignalingClient
struct SignalingClient {
	// MARK: - Configuration
	private let encryptionKey: EncryptionKey
	private let webSocketClient: WebSocketClient
	private let jsonDecoder: JSONDecoder
	private let jsonEncoder: JSONEncoder
	private let connectionID: SignalingServerConnectionID
	private let idBuilder: @Sendable () -> RequestID
        private let ownClientId: ClientID

	// MARK: - Streams
	private let incommingMessages: AnyAsyncSequence<IncommingMessage>
	private let incommingSignalingServerMessagges: AnyAsyncSequence<IncommingMessage.FromSignalingServer>
	private let incommingRemoteClientMessagges: AnyAsyncSequence<RTCPrimitive>

	let onICECanddiate: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.ICECandidate>>
	let onOffer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Offer>>
	let onAnswer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Answer>>
	let onRemoteClientState: AnyAsyncSequence<IncommingMessage.FromSignalingServer.Notification>

	// MARK: - Initializer

	init(encryptionKey: EncryptionKey,
	     webSocketClient: WebSocketClient,
	     connectionID: SignalingServerConnectionID,
	     idBuilder: @Sendable @escaping () -> RequestID = { .init(UUID().uuidString) },
             ownClientId: ClientID = .init(UUID().uuidString),
	     jsonDecoder: JSONDecoder = .init(),
	     jsonEncoder: JSONEncoder = .init())
	{
		self.encryptionKey = encryptionKey
		self.webSocketClient = webSocketClient
		self.connectionID = connectionID
		self.idBuilder = idBuilder
                self.ownClientId = ownClientId
		self.jsonEncoder = jsonEncoder
		self.jsonDecoder = jsonDecoder

		self.incommingMessages = webSocketClient
			.incomingMessageStream
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
			.mapSkippingError { [encryption = encryptionKey] message in
				try message.extractRTCPrimitive(encryption, decoder: jsonDecoder)
			} logError: { error in
				loggerGlobal.info("Failed to extract RTCPrimitive - \(error)")
			}
			.eraseToAnyAsyncSequence()

		self.incommingSignalingServerMessagges = self.incommingMessages
			.compactMap(\.fromSignalingServer)
			.eraseToAnyAsyncSequence()

		self.onOffer = self.incommingRemoteClientMessagges
			.compactMap(\.offer)
			.logInfo("Received Offer from remote client: %@")
			.eraseToAnyAsyncSequence()

		self.onAnswer = self.incommingRemoteClientMessagges
			.compactMap(\.answer)
			.logInfo("Received Answer from remote client: %@")
			.eraseToAnyAsyncSequence()

		self.onICECanddiate = self.incommingRemoteClientMessagges
			.compactMap(\.addICE)
			.logInfo("Received ICECandidate from remote client: %@")
			.eraseToAnyAsyncSequence()

		self.onRemoteClientState = self.incommingSignalingServerMessagges
			.compactMap(\.notification)
			.logInfo("Received Notification from Signaling Server: %@")
			.eraseToAnyAsyncSequence()
	}

	public func sendToRemote(rtcPrimitive: RTCPrimitive) async throws {
		let id = idBuilder()
		let encodedPrimitive = try jsonEncoder.encode(rtcPrimitive)
		let encryptedPrimitive = try encryptionKey.encrypt(data: encodedPrimitive)
		let encryptedPayload = EncryptedPayload(.init(data: encryptedPrimitive))

		let message = ClientMessage(requestId: id,
		                            method: .init(from: rtcPrimitive),
		                            source: .wallet,
                                            sourceClientId: ownClientId,
                                            targetClientId: rtcPrimitive.clientId,
		                            connectionId: connectionID,
		                            encryptedPayload: encryptedPayload)

		let encodedMessage = try jsonEncoder.encode(message)

		loggerGlobal.info("Sending message to remote client")
		try await webSocketClient.send(message: encodedMessage)
		try await waitForRequestAck(id)
		loggerGlobal.info("Message sent to remote client")
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

extension AsyncSequence {
	func mapSkippingError<NewValue: Sendable>(
		_ f: @Sendable @escaping (Element) async throws -> NewValue,
		logError: @Sendable @escaping (Error) -> Void = { _ in }
	) -> AnyAsyncSequence<NewValue> where Element: Sendable, Self: Sendable {
		compactMap { element in
			do {
				return try await f(element)
			} catch {
				logError(error)
				return nil
			}
		}.eraseToAnyAsyncSequence()
	}
}

extension AsyncSequence {
	func logInfo(
		_ message: String
	) -> AnyAsyncSequence<Element> where Element: Sendable, Self: Sendable {
		handleEvents(onElement: { element in
			loggerGlobal.info(.init(stringLiteral: String(format: message, "\(dump(element))")))
		}).eraseToAnyAsyncSequence()
	}
}
