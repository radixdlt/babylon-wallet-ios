import Foundation

extension ChunkedMessagePackage {
	public typealias MessageID = String

	public var messageId: MessageID {
		switch self {
		case let .chunk(value): return value.messageId
		case let .metaData(value): return value.messageId
		case let .receiveMessageConfirmation(value): return value.messageId
		case let .receiveMessageError(value): return value.messageId
		}
	}
}
