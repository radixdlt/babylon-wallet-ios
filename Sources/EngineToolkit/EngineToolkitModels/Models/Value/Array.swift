import Foundation

// MARK: - Array_
public struct Array_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .array
	public func embedValue() -> Value_ {
		.array(self)
	}

	// MARK: Stored properties

	public let elementKind: ValueKind
	public let elements: [Value_]

	// MARK: Init

	public init(
		elementKind: ValueKind,
		elements: [Value_]
	) throws {
		self.elementKind = elementKind
		self.elements = elements
	}

	public init(
		elementKind: ValueKind,
		@ValuesBuilder buildValues: () throws -> [ValueProtocol]
	) throws {
		try self.init(
			elementKind: elementKind,
			elements: buildValues().map { $0.embedValue() }
		)
	}

	public init(
		elementKind: ValueKind,
		@SpecificValuesBuilder buildValues: () throws -> [Value_]
	) throws {
		try self.init(
			elementKind: elementKind,
			elements: buildValues()
		)
	}
}

// MARK: Array_.Error
extension Array_ {
	public enum Error: String, Swift.Error, Sendable, Hashable {
		case homogeneousArrayRequired
	}
}

extension Array_ {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case elements, elementKind = "element_kind", type
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(elements, forKey: .elements)
		try container.encode(elementKind, forKey: .elementKind)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			elementKind: container.decode(ValueKind.self, forKey: .elementKind),
			elements: container.decode([Value_].self, forKey: .elements)
		)
	}
}
