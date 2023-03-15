import AsyncExtensions
import Foundation
import Prelude

// MARK: - SignalingTransport
/// The Transport used to send and receive messages
protocol SignalingTransport: Sendable {
	var incomingMessages: AsyncStream<Data> { get }
	func send(message: Data) async throws

	func cancel() async
}

// MARK: - SignalingClient
/// The client communicating with SignalingServer
struct SignalingClient: Sendable {
	// MARK: - Configuration

	/// The transport to be used to send and receive client messages
	private let transport: SignalingTransport
	private let clientSource: ClientSource
	/// Key to be used to encrypt/decrypt client messages
	private let encryptionKey: EncryptionKey
	private let jsonDecoder: JSONDecoder
	private let jsonEncoder: JSONEncoder
	private let idBuilder: @Sendable () -> ClientMessage.RequestID

	// MARK: - Streams
	private let incomingMessages: AnyAsyncSequence<IncomingMessage>
	private let incomingSignalingServerMessagges: AnyAsyncSequence<IncomingMessage.FromSignalingServer>
	private let incomingRemoteClientMessagges: AnyAsyncSequence<IncomingMessage.RemoteData>

	/// The received ICECandidates
	let onICECanddiate: AnyAsyncSequence<IdentifiedRTCICECandidate>
	/// The received Offers
	let onOffer: AnyAsyncSequence<IdentifiedRTCOffer>
	/// The received Answers
	let onAnswer: AnyAsyncSequence<IdentifiedRTCAnswer>
	/// The received client state notifications
	let onRemoteClientState: AnyAsyncSequence<IncomingMessage.FromSignalingServer.Notification>

	// MARK: - Initializer

	init(encryptionKey: EncryptionKey,
	     transport: SignalingTransport,
	     idBuilder: @Sendable @escaping () -> ClientMessage.RequestID = { .init(UUID().uuidString) },
	     jsonDecoder: JSONDecoder = .init(),
	     jsonEncoder: JSONEncoder = .init(),
	     clientSource: ClientSource = .wallet)
	{
		self.encryptionKey = encryptionKey
		self.transport = transport
		self.idBuilder = idBuilder
		self.jsonEncoder = jsonEncoder
		self.jsonDecoder = jsonDecoder
		self.clientSource = clientSource
		self.jsonDecoder.userInfo[.clientMessageEncryptonKey] = encryptionKey
		self.jsonEncoder.userInfo[.clientMessageEncryptonKey] = encryptionKey

		self.incomingMessages = transport
			.incomingMessages
			.eraseToAnyAsyncSequence()
			.mapSkippingError {
				try jsonDecoder.decode(IncomingMessage.self, from: $0)
			} logError: { error in
				loggerGlobal.info("Failed to decode Incoming Message - \(error)")
			}
			.share()
			.eraseToAnyAsyncSequence()

		self.incomingRemoteClientMessagges = self.incomingMessages
			.compactMap(\.fromRemoteClient)
			.share()
			.eraseToAnyAsyncSequence()

		self.incomingSignalingServerMessagges = self.incomingMessages
			.compactMap(\.fromSignalingServer)
			.eraseToAnyAsyncSequence()

		self.onOffer = self.incomingRemoteClientMessagges
			.compactMap(\.offer)
			.share()
			.eraseToAnyAsyncSequence()

		self.onAnswer = self.incomingRemoteClientMessagges
			.compactMap(\.answer)
			.share()
			.eraseToAnyAsyncSequence()

		self.onICECanddiate = self.incomingRemoteClientMessagges
			.compactMap(\.iceCandidate)
			.share()
			.eraseToAnyAsyncSequence()

		self.onRemoteClientState = self.incomingSignalingServerMessagges
			.compactMap(\.notification)
			.share()
			.eraseToAnyAsyncSequence()
	}

	// MARK: - Public API

	/// Cancel all ongoing tasks and prepare for deallocation
	func cancel() {
		Task {
			await transport.cancel()
		}
	}

	/// Send the given primitive to remote client. Will await for receive confirmation
	func sendToRemote(_ primitive: IdentifiedRTCPrimitive) async throws {
		let message = ClientMessage(
			requestId: idBuilder(),
			targetClientId: primitive.id,
			primitive: primitive.content
		)
		let encodedMessage = try jsonEncoder.encode(message)
		try await transport.send(message: encodedMessage)
		try await waitForRequestAck(message.requestId)
	}

	// MARK: - Private API

	private func waitForRequestAck(_ requestId: ClientMessage.RequestID) async throws {
		try await self.incomingSignalingServerMessagges
			.compactMap(\.responseForRequest)
			.compactMap { incoming in
				try incoming.resultOfRequest(id: requestId)?.get()
			}
			.first { true }
	}
}
