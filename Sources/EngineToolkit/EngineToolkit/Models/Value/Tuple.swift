import Foundation

// MARK: - Tuple
public struct Tuple: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByRadixEngineValues {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .tuple
	public func embedValue() -> Value_ {
		.tuple(self)
	}

	// MARK: Stored properties
	public let elements: [Value_]

	// MARK: Init

	public init(values: [Value_]) {
		self.elements = values
	}
}

public extension Tuple {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case elements, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(elements, forKey: .elements)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `elements`
		// TODO: Validate that all elements are of type `elementType`
		try self.init(values: container.decode([Value_].self, forKey: .elements))
	}
}
