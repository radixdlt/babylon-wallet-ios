import Foundation

// MARK: - Optional + ValueProtocol
extension Optional: ValueProtocol where Wrapped == Value_ {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .option
	public func embedValue() -> Value_ {
		.option(self)
	}
}

public extension Optional where Wrapped == Value_ {
	static func some(_ value: ValueProtocol) -> Self {
		Self.some(value.embedValue())
	}

	init(@ValuesBuilder buildSome: () throws -> ValueProtocol) rethrows {
		self = Self.some(try buildSome())
	}

	init(@SpecificValuesBuilder buildSome: () throws -> Value_) rethrows {
		self = Self.some(try buildSome())
	}
}

// MARK: - Optional + ProxyCodable
extension Optional: ProxyCodable where Wrapped == Value_ {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case variant
		case type
		case field
	}

	private enum Discriminator: String, Codable {
		case some = "Some"
		case none = "None"
	}

	private var discriminator: Discriminator {
		switch self {
		case .none: return .none
		case .some: return .some
		}
	}

	public struct ProxyDecodable: DecodableProxy {
		public typealias Decoded = Value_?
		public let decoded: Decoded
		public init(from decoder: Decoder) throws {
			// Checking for type discriminator
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
			if kind != Decoded.kind {
				throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Decoded.kind, butGot: kind)
			}

			let discriminator = try container.decode(Discriminator.self, forKey: .variant)
			switch discriminator {
			case .some:
				let value: Value_ = try container.decode(Value_.self, forKey: .field)
				decoded = .some(value)
			case .none:
				decoded = .none
			}
		}
	}

	public struct ProxyEncodable: EncodableProxy {
		public typealias ToEncode = Value_?
		public let toEncode: ToEncode
		public init(toEncode: ToEncode) {
			self.toEncode = toEncode
		}

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(toEncode.kind, forKey: .type)
			try container.encode(toEncode.discriminator, forKey: .variant)

			// Encode depending on whether this is a Some or None
			switch toEncode {
			case let .some(value):
				try container.encode(value, forKey: .field)
			case .none: break
			}
		}
	}
}
