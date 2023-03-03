import AsyncExtensions
import Foundation
import Prelude

// MARK: - SignalingTransport
/// The Transport used to send and receive messages
protocol SignalingTransport: Sendable {
	var incommingMessages: AsyncStream<Data> { get }
	func send(message: Data) async throws

	func cancel() async
}

// MARK: - SignalingClient
struct SignalingClient {
	enum ClientSource: String, Sendable, Codable, Equatable {
		case wallet
		case `extension`
	}

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
	private let incommingMessages: AnyAsyncSequence<IncommingMessage>
	private let incommingSignalingServerMessagges: AnyAsyncSequence<IncommingMessage.FromSignalingServer>
	private let incommingRemoteClientMessagges: AnyAsyncSequence<IncommingMessage.RemoteData>

	let onICECanddiate: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.ICECandidate>>
	let onOffer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Offer>>
	let onAnswer: AnyAsyncSequence<IdentifiedPrimitive<RTCPrimitive.Answer>>
	let onRemoteClientState: AnyAsyncSequence<IncommingMessage.FromSignalingServer.Notification>

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

		self.incommingMessages = transport
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
			.share()
			.eraseToAnyAsyncSequence()

		self.incommingSignalingServerMessagges = self.incommingMessages
			.compactMap(\.fromSignalingServer)
			.eraseToAnyAsyncSequence()

		self.onOffer = self.incommingRemoteClientMessagges
			.compactMap(\.offer)
			.share()
			.eraseToAnyAsyncSequence()

		self.onAnswer = self.incommingRemoteClientMessagges
			.compactMap(\.answer)
			.share()
			.eraseToAnyAsyncSequence()

		self.onICECanddiate = self.incommingRemoteClientMessagges
			.compactMap(\.iceCandidate)
			.share()
			.eraseToAnyAsyncSequence()

		self.onRemoteClientState = self.incommingSignalingServerMessagges
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
	func sendToRemote(_ primitive: IdentifiedPrimitive<RTCPrimitive>) async throws {
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
		try await self.incommingSignalingServerMessagges
			.compactMap(\.responseForRequest)
			.compactMap { incoming in
				try incoming.resultOfRequest(id: requestId)?.get()
			}
			.first { true }
	}
}
