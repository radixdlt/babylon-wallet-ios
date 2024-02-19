import Foundation

extension CoreAPI {
	public enum PlaintextMessageContent: Codable, Hashable {
		case string(StringPlaintextMessageContent)
		case binary(BinaryPlaintextMessageContent)

		enum CodingKeys: String, CodingKey {
			case type
		}

		public var string: String? {
			guard case let .string(value) = self else { return nil }
			return value.value
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			if let type = try? container.decode(PlaintextMessageContentType.self, forKey: .type) {
				switch type {
				case .string:
					self = try .string(.init(from: decoder))
				case .binary:
					self = try .binary(.init(from: decoder))
				}
			} else {
				throw DecodingError.keyNotFound(CodingKeys.type, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Type key not found or invalid"))
			}
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			switch self {
			case let .string(value):
				try container.encode(PlaintextMessageContentType.string, forKey: .type)
				try value.encode(to: encoder)
			case let .binary(value):
				try container.encode(PlaintextMessageContentType.binary, forKey: .type)
				try value.encode(to: encoder)
			}
		}
	}

	public enum PlaintextMessageContentType: String, Codable, CaseIterable {
		case string = "String"
		case binary = "Binary"
	}
}
