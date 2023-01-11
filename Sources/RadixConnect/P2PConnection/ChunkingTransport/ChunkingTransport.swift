import Combine
import Foundation
import Logging
import P2PModels

// MARK: - HandledMessagesByPeers
// The rationale for using a GlobalActor here is that if we destroy and recreate peers we still do
// we want something that outlives that, we want a global, idempotent filter, ensuring we NEVER show
// the actual same dApp request twice to the user.
internal actor HandledMessagesByPeers: GlobalActor {
	actor HandledMessagesByPeer {
		internal let peerID: P2PConnectionID
		private var handledMessagesByContentHash: Set<Key> = .init()
		private struct Key: Hashable {
			private let messageHash: Data
			init(incomingMessage: ChunkingTransportIncomingMessage) {
				self.messageHash = incomingMessage.messageHash
			}
		}

		func finishedHandling(message: ChunkingTransportIncomingMessage) async {
			let key = Key(incomingMessage: message)
			guard !handledMessagesByContentHash.contains(key) else {
				loggerGlobal.warning("Already handled message: \(String(describing: message)), bad Application Layer logic.")
				return
			}
			handledMessagesByContentHash.insert(key)
		}

		func hasHandled(message: ChunkingTransportIncomingMessage) async -> Bool {
			let key = Key(incomingMessage: message)
			return handledMessagesByContentHash.contains(key)
		}

		fileprivate init(peerID: P2PConnectionID) {
			self.peerID = peerID
		}
	}

	private var handledMessagesForPeer: [P2PConnectionID: HandledMessagesByPeer] = [:]
	private init() {}
	internal static let shared = HandledMessagesByPeers()
	internal static func finishedHandling(message: ChunkingTransportIncomingMessage, peerID: P2PConnectionID) async {
		let handler = await shared.handledMessagesForPeer[peerID, default: .init(peerID: peerID)]
		await handler.finishedHandling(message: message)
	}

	internal static func hasHandled(message: ChunkingTransportIncomingMessage, peerID: P2PConnectionID) async -> Bool {
		let handler = await shared.handledMessagesForPeer[peerID, default: .init(peerID: peerID)]
		return await handler.hasHandled(message: message)
	}
}

// MARK: - ChunkingTransport
public final class ChunkingTransport {
	public let connectionID: P2PConnectionID

	private let splitter: MessageSplitter = .init()
	private let chunkedMessageReceiver: ChunkedMessageReceiver = .init()
	private var outgoingMessagesPending: [MessageID: ChunkingTransportOutgoingMessage] = [:]

	private let incomingMessagesSubject: PassthroughSubject<IncomingMessage, Error> = .init()
	private let outgoingMessageConfirmedSubject: PassthroughSubject<SentReceipt, Error> = .init()

	private let jsonEncoder: JSONEncoder = .init()

	private let send: Send

	public init(
		connectionID: P2PConnectionID,
		send: @escaping Send
	) {
		self.connectionID = connectionID
		self.send = send
	}
}

public extension ChunkingTransport {
	typealias Error = ConverseError
	typealias Send = @Sendable (Data) throws -> Void

	typealias MessageID = ChunkedMessagePackage.MessageID
	typealias IncomingMessage = ChunkingTransportIncomingMessage
	typealias OutgoingMessage = ChunkingTransportOutgoingMessage
	typealias SentReceipt = ChunkingTransportSentReceipt
}

public extension ChunkingTransport {
	var outgoingMessageConfirmedPublisher: AnyPublisher<SentReceipt, Error> {
		outgoingMessageConfirmedSubject.eraseToAnyPublisher()
	}

	var incomingMessagesPublisher: AnyPublisher<IncomingMessage, Error> {
		incomingMessagesSubject.eraseToAnyPublisher()
	}
}

public extension ChunkingTransport {
	func send(
		data message: Data,
		messageID: MessageID
	) throws {
		precondition(outgoingMessagesPending[messageID] == nil, "Incorrect implementation, expected to not add pending outgoing msg twice")
		outgoingMessagesPending[messageID] = .init(data: message, messageID: messageID)
		let packages = try splitter.split(message: message, messageID: messageID)
		for package in packages {
			try encodeAndSend(package: package)
		}
	}

	func webRTCClientIncomingMessage(completedWith completion: Subscribers.Completion<ConverseError>) {
		incomingMessagesSubject.send(completion: completion)
	}

	func receive(messageFromWebRTC: IncomingWebRTCMessage) {
		let connectionID = self.connectionID
		do {
			guard let assembled = try handleChunkedMessagePackageJSONData(messageFromWebRTC.message) else {
				return
			}
			switch assembled {
			case let .incomingMessage(incomingMessage):
				Task { [weak self] in
					guard await !HandledMessagesByPeers.hasHandled(message: incomingMessage, peerID: connectionID) else {
						loggerGlobal.warning("Received Incoming Message from Dapp that you have already handled, this is a discrepancy in SendMessageReceipt and has handled message (based on content) logic. Did mark message as 'handled' without sending a message confirmation (receipt)?. This message will be IGNORED and not published further up the application stack.")
						return
					}
					self?.incomingMessagesSubject.send(incomingMessage)
				}
			case let .outgoingMessageGotReceivedConfirmation(confirmationSentOutgoingMessage):
				loggerGlobal.trace("Got confirmation of outgoing message with ID: \(confirmationSentOutgoingMessage.messageId)")
				try self.gotConfirmationFor(outgoingMessage: confirmationSentOutgoingMessage)
			}
		} catch {
			let failure = ConverseError.chunkingTransport(ConverseError.ChunkingTransportError(error: error))
			loggerGlobal.error("Failed to assemble error from webRTC incoming message, error: \(failure.localizedDescription)")
			self.incomingMessagesSubject.send(completion: .failure(failure))
		}
	}

	/// This does NOT send a message read confirmation (receipt), this adds this message to a filter ensuring if
	/// the dApp resends this message due to this side not having sent a message read confirmation response in time
	/// that we do not display the same message twice.
	func markMessageAsHandled(_ incomingMessage: IncomingMessage) async {
		await HandledMessagesByPeers.finishedHandling(message: incomingMessage, peerID: connectionID)
	}

	func sendReceiveMessageConfirmation(
		for incomingMessage: IncomingMessage,
		markMessageAsHandled: Bool = true
	) throws {
		let confirmation = ChunkedMessageReceiveConfirmation(messageID: incomingMessage.messageID)
		let package = ChunkedMessagePackage.receiveMessageConfirmation(confirmation)
		if markMessageAsHandled {
			Task { [weak self] in
				await self?.markMessageAsHandled(incomingMessage)
			}
		}
		try encodeAndSend(package: package)
	}
}

private extension ChunkingTransport {
	func gotConfirmationFor(
		outgoingMessage confirmedSentOutgoingMsg: ChunkedMessageReceiver.Message.Outgoing
	) throws {
		let msgId = confirmedSentOutgoingMsg.messageId

		guard let pendingOutgoingMsg = outgoingMessagesPending[msgId] else {
			loggerGlobal.notice("Got confirmation of outgoing message with ID: \(msgId). but was not in pending outgoing dict, ignoring.")
			return
		}

		precondition(pendingOutgoingMsg.messageID == msgId)

		outgoingMessagesPending.removeValue(forKey: msgId)
		let sentReceipt = SentReceipt(messageSent: pendingOutgoingMsg)
		outgoingMessageConfirmedSubject.send(sentReceipt)
	}

	func encodeAndSend<Model: Encodable>(
		model: Model
	) throws {
		loggerGlobal.trace("JSON Encoding model before sending it over p2p, model is of type: \(Model.self) and value: \(String(describing: model))")
		let message = try jsonEncoder.encode(model)
		loggerGlobal.trace("Finished JSON encoding model of type \(Model.self) => sending over P2P now.")
		try send(message)
	}

	func encodeAndSend(package: ChunkedMessagePackage) throws {
		loggerGlobal.trace("⬆️ sending package over P2P: \(String(describing: package.packageType)), messageId: \(package.messageId)")
		try encodeAndSend(model: package)
	}

	func handleChunkedMessagePackageJSONData(
		_ packageJSONData: Data
	) throws -> ChunkedMessageReceiver.Message? {
		loggerGlobal.trace("⬇️ 🥩 RAW received #\(packageJSONData.count) bytes over P2P channel")
		return try chunkedMessageReceiver.receive(packageJSONData: packageJSONData)
	}
}
