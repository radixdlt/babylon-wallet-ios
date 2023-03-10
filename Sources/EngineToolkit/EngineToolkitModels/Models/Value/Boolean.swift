import Foundation

// MARK: - Bool + ValueProtocol
extension Bool: ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .bool
	public func embedValue() -> ManifestASTValue {
		.boolean(self)
	}
}

// MARK: - Bool + ProxyCodable
extension Bool: ProxyCodable {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	public struct ProxyDecodable: DecodableProxy {
		public typealias Decoded = Bool
		public let decoded: Decoded
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
			if kind != Decoded.kind {
				throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Decoded.kind, butGot: kind)
			}

			// Decoding `value`
			self.decoded = try container.decode(Bool.self, forKey: .value)
		}
	}

	public struct ProxyEncodable: EncodableProxy {
		public typealias ToEncode = Bool
		public let toEncode: ToEncode
		public init(toEncode: ToEncode) {
			self.toEncode = toEncode
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ToEncode.kind, forKey: .type)
			try container.encode(toEncode, forKey: .value)
		}
	}
}
