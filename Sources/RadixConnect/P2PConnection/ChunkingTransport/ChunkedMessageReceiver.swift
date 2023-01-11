import Foundation
import Logging
import P2PModels

// MARK: - ChunkedMessageReceiver
public final class ChunkedMessageReceiver {
	private let assembler: ChunkedMessagePackageAssembler
	private let jsonDecoder: JSONDecoder
	// internal for tests
	internal var receivedPackagesByMessageId: [ChunkedMessagePackage.MessageID: [ChunkedMessagePackage]] = [:]

	public init(
		assembler: ChunkedMessagePackageAssembler = .init(),
		jsonDecoder: JSONDecoder = .init()
	) {
		self.assembler = assembler
		self.jsonDecoder = jsonDecoder
	}
}

public extension ChunkedMessageReceiver {
	func receive(
		packageJSONData data: Data
	) throws -> Message? {
		loggerGlobal.trace("⬇️☑️ Trying to JSON decode package json data into ChunkedMessagePackage")
		let package = try jsonDecoder.decode(ChunkedMessagePackage.self, from: data)
		loggerGlobal.trace("⬇️✅ JSON decoded package json data into ChunkedMessagePackage: \(String(describing: package))")

		loggerGlobal.trace("⬇️ Chunked message with type: '\(String(describing: package.packageType))', id: \(package.messageId)")

		return try receive(package: package)
	}

	func receive(package: ChunkedMessagePackage) throws -> Message? {
		if let receiveMessageError = package.receiveMessageError {
			throw receiveMessageError
		}
		let messageId = package.messageId
		let alreadyReceivedPackages = receivedPackagesByMessageId[messageId]

		switch (package, alreadyReceivedPackages) {
		case (.metaData(_), .some(_)):
			throw Error.alreadyGotMetaData(forMessageWithID: messageId)

		case (.metaData(_), .none):
			receivedPackagesByMessageId[messageId] = [package]

		case let (.chunk(chunk), .some(alreadyReceivedPackages)):
			let packages = alreadyReceivedPackages + [package]
			guard let metaData = packages.first?.metaData else {
				throw Error.expectedFirstPackageToBeMetaDataPackage
			}
			if chunk.chunkIndex + 1 == metaData.chunkCount {
				do {
					let message = try assembler.assemble(packages: packages)
					receivedPackagesByMessageId.removeValue(forKey: messageId)
					let incomingMessage = Message.Incoming(
						messagePayload: message.messageContent,
						messageID: messageId,
						messageHash: message.messageHash
					)

					return .incomingMessage(incomingMessage)
				} catch let assembleError as ChunkedMessagePackageAssembler.Error {
					throw Error.failedToAssembleMessage(assembleError)
				} catch {
					throw Error.unknownError(error)
				}
			} else {
				receivedPackagesByMessageId[messageId] = packages
				return nil
			}

		case let (.receiveMessageConfirmation(receivedMessageConfirmation), _):
			return .outgoingMessageGotReceivedConfirmation(.init(messageId: receivedMessageConfirmation.messageId))

		case let (.receiveMessageError(receiveMsgError), _):
			throw Error.receivedMessageError(receiveMsgError)

		default:
			throw Error.invalidStateWhenReceivingPackage
		}

		return nil
	}
}

// MARK: ChunkedMessageReceiver.Message
public extension ChunkedMessageReceiver {
	enum Message: Sendable, Hashable {
		case outgoingMessageGotReceivedConfirmation(Outgoing)
		case incomingMessage(Incoming)
	}
}

public extension ChunkedMessageReceiver.Message {
	struct Outgoing: Sendable, Hashable {
		public let messageId: ChunkedMessagePackage.MessageID
		public init(messageId: ChunkedMessagePackage.MessageID) {
			self.messageId = messageId
		}
	}

	typealias Incoming = ChunkingTransportIncomingMessage
}

public extension ChunkedMessageReceiver.Message {
	var messageId: ChunkedMessagePackage.MessageID {
		switch self {
		case let .outgoingMessageGotReceivedConfirmation(value): return value.messageId
		case let .incomingMessage(value): return value.messageID
		}
	}

	var incoming: Incoming? {
		guard case let .incomingMessage(value) = self else {
			return nil
		}
		return value
	}

	var outgoingMessageGotReceivedConfirmation: Outgoing? {
		guard case let .outgoingMessageGotReceivedConfirmation(value) = self else {
			return nil
		}
		return value
	}
}

// MARK: - ChunkedMessageReceiver.Error
public extension ChunkedMessageReceiver {
	typealias Error = ConverseError.ChunkingTransportError.ReceiveError
}
