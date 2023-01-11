import Foundation

public extension ChunkedMessagePackage {
	var metaData: ChunkedMessageMetaDataPackage? {
		guard case let .metaData(value) = self else {
			return nil
		}
		return value
	}

	var chunk: ChunkedMessageChunkPackage? {
		guard case let .chunk(value) = self else {
			return nil
		}
		return value
	}

	var receiveMessageConfirmation: ChunkedMessageReceiveConfirmation? {
		guard case let .receiveMessageConfirmation(value) = self else {
			return nil
		}
		return value
	}

	var receiveMessageError: ChunkedMessageReceiveError? {
		guard case let .receiveMessageError(value) = self else {
			return nil
		}
		return value
	}
}
