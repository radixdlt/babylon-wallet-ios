import Foundation

extension DataChannelClient.Message {
	enum PackageType: String, Codable {
		case metaData
		case chunk
		case receiveMessageConfirmation
		case receiveMessageError
	}

	var packageType: PackageType {
		switch self {
		case .chunkedMessage(.metaData): return .metaData
		case .chunkedMessage(.chunk): return .chunk
		case .receipt(.receiveMessageConfirmation): return .receiveMessageConfirmation
		case .receipt(.receiveMessageError): return .receiveMessageError
		}
	}

	enum CodingKeys: String, CodingKey {
		case packageType
	}

	init(from decoder: Decoder) throws {
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let container = try decoder.singleValueContainer()
		let packageType = try keyedContainer.decode(PackageType.self, forKey: .packageType)
		switch packageType {
		case .metaData:
			self = try .chunkedMessage(.metaData(
				container.decode(ChunkedMessage.MetaDataPackage.self)
			))
		case .chunk:
			self = try .chunkedMessage(.chunk(
				container.decode(ChunkedMessage.ChunkPackage.self)
			))
		case .receiveMessageConfirmation:
			self = try .receipt(.receiveMessageConfirmation(
				container.decode(Receipt.ReceiveConfirmation.self)
			))
		case .receiveMessageError:
			self = try .receipt(.receiveMessageError(
				container.decode(Receipt.ReceiveError.self)
			))
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		func encodeType() throws {
			var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
			try keyedContainer.encode(packageType, forKey: .packageType)
		}

		switch self {
		case let .chunkedMessage(.chunk(chunk)):
			try container.encode(chunk)
			try encodeType()
		case let .chunkedMessage(.metaData(metaData)):
			try container.encode(metaData)
			try encodeType()
		case let .receipt(.receiveMessageConfirmation(confirmation)):
			try container.encode(confirmation)
			try encodeType()
		case let .receipt(.receiveMessageError(receiveMessageError)):
			try container.encode(receiveMessageError)
			try encodeType()
		}
	}
}
