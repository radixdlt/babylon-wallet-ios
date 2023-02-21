import Foundation

extension ChunkedMessagePackage {
	public var metaData: ChunkedMessageMetaDataPackage? {
		guard case let .metaData(value) = self else {
			return nil
		}
		return value
	}

	public var chunk: ChunkedMessageChunkPackage? {
		guard case let .chunk(value) = self else {
			return nil
		}
		return value
	}

	public var receiveMessageConfirmation: ChunkedMessageReceiveConfirmation? {
		guard case let .receiveMessageConfirmation(value) = self else {
			return nil
		}
		return value
	}

	public var receiveMessageError: ChunkedMessageReceiveError? {
		guard case let .receiveMessageError(value) = self else {
			return nil
		}
		return value
	}
}
