#if canImport(AnyCodable)
import AnyCodable
#endif

extension CoreAPI {
	enum TransactionMessage: Codable, Hashable {
		case plaintext(PlaintextTransactionMessage)
		case encrypted(AnyCodable)

		enum CodingKeys: String, CodingKey {
			case type
		}

		var plaintext: PlaintextTransactionMessage? {
			guard case let .plaintext(value) = self else { return nil }
			return value
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)

			if let type = try? container.decode(TransactionMessageType.self, forKey: .type) {
				switch type {
				case .plaintext:
					self = try .plaintext(.init(from: decoder))
				case .encrypted:
					self = try .encrypted(.init(from: decoder))
				}
			} else {
				throw DecodingError.keyNotFound(CodingKeys.type, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Type key not found or invalid"))
			}
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)

			switch self {
			case let .plaintext(value):
				try container.encode(TransactionMessageType.plaintext, forKey: .type)
				try value.encode(to: encoder)
			case let .encrypted(value):
				try container.encode(TransactionMessageType.encrypted, forKey: .type)
				try value.encode(to: encoder)
			}
		}
	}

	enum TransactionMessageType: String, Codable, CaseIterable {
		case plaintext = "Plaintext"
		case encrypted = "Encrypted"
	}
}
