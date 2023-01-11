import Foundation

public extension ChunkedMessagePackage {
	typealias MessageID = String

	var messageId: MessageID {
		switch self {
		case let .chunk(value): return value.messageId
		case let .metaData(value): return value.messageId
		case let .receiveMessageConfirmation(value): return value.messageId
		case let .receiveMessageError(value): return value.messageId
		}
	}
}
