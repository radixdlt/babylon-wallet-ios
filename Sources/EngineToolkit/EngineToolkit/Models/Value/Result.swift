import Foundation

// MARK: - Value_ + Swift.Error
// Only marked as an `Error` to be able to be used as `Failure` in `Result`.
extension Value_: Swift.Error {}

// MARK: - Result + Codable
extension Result: Codable where Success == Value_, Failure == Value_ {
	private enum Variant: String, Codable, Equatable {
		case success = "Ok"
		case failure = "Err"
	}

	private var variant: Variant {
		switch self {
		case .failure: return .failure
		case .success: return .success
		}
	}

	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case variant
		case type
		case field
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(variant, forKey: .variant)

		// Encode depending on whether this is a Some or None
		switch self {
		case let .success(value):
			try container.encode(value, forKey: .field)
		case let .failure(value):
			try container.encode(value, forKey: .field)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let variant = try container.decode(Variant.self, forKey: .variant)
		let value = try container.decode(Value_.self, forKey: .field)
		switch variant {
		case .success:
			self = .success(value)
		case .failure:
			self = .failure(value)
		}
	}

	public static var kind: ValueKind { .result }
}

// MARK: - Result + ValueProtocol
extension Result: ValueProtocol where Success == Value_, Failure == Value_ {
	public func embedValue() -> Value_ {
		.result(self)
	}
}
