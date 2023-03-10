import Foundation

// TODO: The underscore is added here to avoid name collisions. Something better is needed.
extension String: ValueProtocol, ProxyCodable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .string
	public func embedValue() -> ManifestASTValue {
		.string(self)
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, type
	}

	public struct ProxyDecodable: DecodableProxy {
		public typealias Decoded = String
		public let decoded: Decoded
		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
			if kind != Decoded.kind {
				throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Decoded.kind, butGot: kind)
			}

			// Decoding `value`
			decoded = try container.decode(Decoded.self, forKey: .value)
		}
	}

	public struct ProxyEncodable: EncodableProxy {
		public typealias ToEncode = String
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
