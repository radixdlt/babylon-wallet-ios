import Combine
import P2PModels
import Prelude

// MARK: - SignalingServerClient
public final class SignalingServerClient {
	private let config: SignalingServerConfig
	public let connectionSecrets: ConnectionSecrets
	private let url: URL

	private let receivedMessagesSubject = PassthroughSubject<IncomingMessage, Error>()
	private let rtcPrimitiveExtractorFromRPCMessage: RTCPrimitiveExtractorFromRPCMessage
	private let rtcPrimitiveToMessagePacker: RTCPrimitiveToMessagePacker

	private let stateSubject: CurrentValueSubject<WebSocketState, Never>
	public var webSocketStatePublisher: AnyPublisher<WebSocketState, Never> {
		stateSubject.eraseToAnyPublisher()
	}

	private var webSocketClient: WebSocketClient?

	private let jsonEncoder: JSONEncoder = .init()
	private let jsonDecoder: JSONDecoder = .init()

	private var pingTask: Task<Void, Never>?

	public init(
		config: SignalingServerConfig,
		connectionSecrets: ConnectionSecrets
	) throws {
		self.stateSubject = .init(.new)
		self.config = config
		self.connectionSecrets = connectionSecrets
		self.rtcPrimitiveExtractorFromRPCMessage = .init(connectionSecrets: connectionSecrets)
		self.rtcPrimitiveToMessagePacker = .init(connectionSecrets: connectionSecrets)
		self.url = try config.signalingServerURL(connectionID: connectionSecrets.connectionID)
	}
}

public extension SignalingServerClient {
	typealias IncomingMessage = SignalingServerMessage.Incoming
	typealias OutgoingMessage = SignalingServerMessage.Outgoing
	typealias TransportCallback<Response: Sendable> = @Sendable (Result<Response, Error>) -> Void
	typealias TransportVoidCallback = TransportCallback<Void>
	typealias Error = ConverseError
}

private extension SignalingServerClient {
	func transport(
		rpcPrimitive: WebRTCPrimitive,
		callback: @escaping TransportVoidCallback
	) {
		do {
			let outgoingMessage = try rtcPrimitiveToMessagePacker.pack(primitive: rpcPrimitive)
			guard let webSocketClient else {
				let error = Error.signalingServer(.unableToTransportOutgoingMessageWebSocketClientIsNil)
				loggerGlobal.error("Unable to transport message, webSocketClient is nil")
				receivedMessagesSubject.send(completion: .failure(error))
				return
			}
			do {
				let jsonData = try jsonEncoder.encode(outgoingMessage)
				webSocketClient.send(data: jsonData) { result in
					switch result {
					case let .failure(error):
						loggerGlobal.error("Failed to transport rpc message to Signaling Server, error: \(String(describing: error))")
						callback(.failure(Error.signalingServer(.failedToTransportRPCMessage(webSocketError: error))))
					case .success:
						loggerGlobal.debug("Successfully transported message to signaling server")
						callback(.success(()))
					}
				}
			} catch {
				loggerGlobal.error("Failed to transport rpc message to Signaling Server, failed to JSON encode outgoing message: \(String(describing: error))")
				callback(.failure(Error.signalingServer(.failedToTransportRPCMessageJSONEncodingFailed(underlyingError: error))))
			}
		} catch let error as Error {
			loggerGlobal.error("Failed to transport RPC Primitive, error: \(error.localizedDescription)")
			callback(.failure(error))
		} catch {
			loggerGlobal.error("Failed to transport RPC Primitive, error: \(String(describing: error))")
			callback(.failure(Error.signalingServer(.failedToTransportRPCPrimitiveFailedToPack(underlyingError: error))))
		}
	}

	var incomingMessagesFromSignalingServerPublisher: AnyPublisher<IncomingMessage.FromSignalingServerItself, Error> {
		self.receivedMessagesSubject.compactMap(\.fromSignalingServerItself).eraseToAnyPublisher()
	}

	var incomingRTCPrimitivesPublisher: AnyPublisher<WebRTCPrimitive, Error> {
		receivedMessagesSubject.tryCompactMap { [weak self] incomingMessage in
			guard let self = self else {
				throw Error.signalingServer(.failedToExtractRPCFromIncomingMessageFromSignalingServerSelfIsNil)
			}

			switch incomingMessage {
			case let .fromRemoteClientOriginally(fromRemoteClientOriginally):
				let rpcMessage = try self.rtcPrimitiveExtractorFromRPCMessage.extract(rpcMessage: fromRemoteClientOriginally)
				return rpcMessage
			case .fromSignalingServerItself: return nil
			}
		}
		.mapError { anyError -> Error in
			guard let error = anyError as? Error else {
				return Error.signalingServer(.failedToExtractRPCFromIncomingMessageFromSignalingServer(underlyingError: anyError))
			}
			return error
		}
		.eraseToAnyPublisher()
	}

	func sendPingContinuously() {
		guard let webSocketClient else {
			let error = Error.signalingServer(.unableToPingWebSocketClientIsNil)
			loggerGlobal.error("Unable to send ping, webSocketClient is nil")
			receivedMessagesSubject.send(completion: .failure(error))
			return
		}
		loggerGlobal.trace("Sending ping 🏓")
		webSocketClient.sendPing { [weak self, pingInterval = config.websocketPingInterval] result in
			guard let self = self else {
				loggerGlobal.warning("Unable to send ping, self is nil.")
				return
			}
			switch result {
			case .success:
				loggerGlobal.trace("Got pong 🏓")
				if let pingInterval {
					self.pingTask = Task {
						try? await Task.sleep(
							nanoseconds: UInt64(pingInterval) * NSEC_PER_SEC
						)
						try? Task.checkCancellation()
						guard !Task.isCancelled else {
							loggerGlobal.debug("Aborting ping, task cancelled.")
							return
						}
						self.sendPingContinuously()
					}
				}

			case let .failure(error):
				loggerGlobal.trace("Failed to send ping: \(String(describing: error))")
				self.receivedMessagesSubject.send(completion: .failure(Error.signalingServer(.failedToPingSignalingServer(error))))
			}
		}
	}

	func connectAndStartPinging(didConnect: @escaping @Sendable () -> Void) {
		let webSocketClient = WebSocketClient(url: url, stateSubject: stateSubject)
		self.webSocketClient = webSocketClient
		webSocketClient.connect(didOpen: didConnect)
		sendPingContinuously()
	}

	func parseData(_ data: Data) -> Result<IncomingMessage, Error> {
		do {
			let message = try jsonDecoder.decode(IncomingMessage.self, from: data)
			return .success(message)
		} catch {
			return .failure(.signalingServer(.failedToReceiveMessageDecodingError(error)))
		}
	}

	func parseMessage(_ message: URLSessionWebSocketTask.Message) -> Result<IncomingMessage, Error> {
		switch message {
		case let .string(string):
			loggerGlobal.trace("Inaccuracy received WebSocket message as `String` but expected `Data`, will interpret this String as .utf8 data...")
			let data = Data(string.utf8)
			return parseData(data)
		case let .data(data):
			return parseData(data)
		@unknown default:
			return .failure(.signalingServer(.failedToReceiveMessageReceivedUnexpectedMessageType("\(type(of: message))")))
		}
	}

	func receiveMessage(
		callback: @escaping @Sendable (Result<IncomingMessage, Error>) -> Void
	) {
		guard let webSocketClient else {
			let error = Error.signalingServer(.unableToReceiveMessageWebSocketClientIsNil)
			loggerGlobal.error("Unable to receive message, webSocketClient is nil")
			callback(.failure(error))
			return
		}

		webSocketClient.receiveMessage { [weak self] receiveResult in
			guard let self = self else {
				loggerGlobal.error("Failed to receive message, self is nil")
				return callback(.failure(Error.signalingServer(.unableToReceiveMessageSelfIsNil)))
			}
			let messageResult = receiveResult.mapError { Error.signalingServer(.failedToReceiveMessage($0)) }
				.flatMap { message -> Result<IncomingMessage, Error> in
					let parsedMessage = self.parseMessage(message)
					loggerGlobal.debug("Parsed message from websockets: \(parsedMessage)")
					return parsedMessage
				}
			callback(messageResult)
		}
	}

	func receiveMessagesAndEmitOnSubject() {
		receiveMessage { [weak self] result in
			guard let self = self else {
				loggerGlobal.error("Failed to receive message, self is nil")
				return
			}

			switch result {
			case let .success(message):
				self.receivedMessagesSubject.send(message)
				self.receiveMessagesAndEmitOnSubject()
			case let .failure(error):
				loggerGlobal.critical("Receive WS message error: \(error)")
				self.receivedMessagesSubject.send(completion: .failure(error))
			}
		}
	}
}

public extension SignalingServerClient {
	func connect(didConnect: @escaping @Sendable () -> Void) {
		connectAndStartPinging(didConnect: didConnect)
		receiveMessagesAndEmitOnSubject()
	}

	func close(webSocketDidClose: @escaping @Sendable (URLSessionWebSocketTask.CloseCode?) -> Void) {
		pingTask?.cancel()
		pingTask = nil
		receivedMessagesSubject.send(completion: .finished)
		if let webSocketClient {
			webSocketClient.close { [weak self] closeCode in
				self?.webSocketClient = nil
				webSocketDidClose(closeCode)
			}
		} else {
			webSocketDidClose(nil)
		}
	}

	func sendOffer(_ offer: WebRTCOffer, callback: @escaping TransportVoidCallback) {
		transport(rpcPrimitive: .offer(offer), callback: callback)
	}

	func sendAnswer(_ answer: WebRTCAnswer, callback: @escaping TransportVoidCallback) {
		transport(rpcPrimitive: .answer(answer), callback: callback)
	}

	func sendICECandidate(_ iceCandidate: WebRTCICECandidate, callback: @escaping TransportVoidCallback) {
		transport(rpcPrimitive: .iceCandidate(iceCandidate), callback: callback)
	}
}

// MARK: Combine
private extension SignalingServerClient {
	func transport(rpcPrimitive: WebRTCPrimitive) -> Future<Void, Error> {
		Future { [weak self] promise in
			guard let self = self else {
				let error = Error.signalingServer(.failedToTransportRPCPrimitiveSelfIsNil)
				loggerGlobal.error("Failed to transport rpc primitive, self is nil.")
				promise(.failure(error))
				return
			}
			self.transport(rpcPrimitive: rpcPrimitive) { result in
				promise(result)
			}
		}
	}
}

public extension SignalingServerClient {
	var remoteClientJustConnectedPublisher: AnyPublisher<Void, Error> {
		incomingMessagesFromSignalingServerPublisher
			.filter(\.isRemoteClientJustConnected)
			.map { _ in }
			.eraseToAnyPublisher()
	}

	var remoteClientIsAlreadyConnectedPublisher: AnyPublisher<Void, Error> {
		incomingMessagesFromSignalingServerPublisher
			.filter(\.isRemoteClientIsAlreadyConnected)
			.map { _ in }
			.eraseToAnyPublisher()
	}

	var remoteClientIsAlreadyConnectedOrJustConnectedPublisher: AnyPublisher<Void, Error> {
		incomingMessagesFromSignalingServerPublisher
			.filter(\.isRemoteClientConnected)
			.map { _ in }
			.eraseToAnyPublisher()
	}

	func sendingOffer(_ offer: WebRTCOffer) -> AnyPublisher<Void, Error> {
		transport(rpcPrimitive: .offer(offer)).eraseToAnyPublisher()
	}

	func sendingICECandidate(_ iceCandidate: WebRTCICECandidate) -> AnyPublisher<Void, Error> {
		transport(rpcPrimitive: .iceCandidate(iceCandidate)).eraseToAnyPublisher()
	}

	func sendingAnswer(_ answer: WebRTCAnswer) -> AnyPublisher<Void, Error> {
		transport(rpcPrimitive: .answer(answer)).eraseToAnyPublisher()
	}
}

// MARK: Async
private extension SignalingServerClient {
	func transport(rpcPrimitive: WebRTCPrimitive) async throws {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
			guard let self = self else {
				let error = Error.signalingServer(.failedToTransportRPCPrimitiveSelfIsNil)
				loggerGlobal.error("Failed to transport rpc primitive, self is nil.")
				continuation.resume(throwing: error)
				return
			}
			self.transport(rpcPrimitive: rpcPrimitive) { result in
				continuation.resume(with: result)
			}
		}
	}
}

public extension SignalingServerClient {
	func remoteClientConnected() async throws {
		try await remoteClientIsAlreadyConnectedOrJustConnectedPublisher.async()
	}

	func disconnect() async throws {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
			guard let self = self else {
				let error = Error.signalingServer(.failedToDisconnectSignalingServerSelfIsNil)
				continuation.resume(throwing: error)
				return
			}
			loggerGlobal.debug("☑️ Disconnected from signaling server with web socket close...")
			self.close { websocketCloseCode in
				loggerGlobal.debug("✅ Successfully disconnected from signaling server with web socket close code: \(String(describing: websocketCloseCode)).")
				continuation.resume(returning: ())
			}
		}
	}

	func connect() async throws {
		try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
			guard let self = self else {
				let error = Error.signalingServer(.failedToConnectToWebSocketSelfIsNil)
				loggerGlobal.error("Failed to connect to signaling server over web socket, self is nil.")
				continuation.resume(throwing: error)
				return
			}
			self.connect {
				continuation.resume(returning: ())
			}
		}
	}

	func sendOffer(_ offer: WebRTCOffer) async throws {
		try await transport(rpcPrimitive: .offer(offer))
	}

	func sendICECandidates(_ iceCandidate: WebRTCICECandidate) async throws {
		try await transport(rpcPrimitive: .iceCandidate(iceCandidate))
	}

	func sendAnswer(_ answer: WebRTCAnswer) async throws {
		try await transport(rpcPrimitive: .answer(answer))
	}

	var answerFromRemoteClientPublisher: AnyPublisher<WebRTCAnswer, Error> {
		incomingRTCPrimitivesPublisher.compactMap(\.answer).eraseToAnyPublisher()
	}

	func receiveAnswerFromRemoteClient() async throws -> WebRTCAnswer {
		try await answerFromRemoteClientPublisher.async()
	}

	var iceCandidateFromRemoteClientPublisher: AnyPublisher<WebRTCICECandidate, Error> {
		incomingRTCPrimitivesPublisher.compactMap(\.iceCandidate).eraseToAnyPublisher()
	}

	func receiveRemoteICECandidate() async throws -> WebRTCICECandidate {
		try await iceCandidateFromRemoteClientPublisher.async()
	}
}
