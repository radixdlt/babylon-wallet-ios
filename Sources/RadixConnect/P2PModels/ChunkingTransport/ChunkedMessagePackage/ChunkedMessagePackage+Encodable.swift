import Foundation

extension ChunkedMessagePackage {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		func encodePackageType() throws {
			var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
			try keyedContainer.encode(packageType, forKey: .packageType)
		}

		switch self {
		case let .chunk(chunk):
			try container.encode(chunk)
			try encodePackageType()

		case let .metaData(metaData):
			try container.encode(metaData)
			try encodePackageType()

		case let .receiveMessageConfirmation(confirmation):
			try container.encode(confirmation)
			try encodePackageType()

		case let .receiveMessageError(receiveMessageError):
			try container.encode(receiveMessageError)
			try encodePackageType()
		}
	}
}
