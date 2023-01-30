import Foundation

// MARK: - Map
public struct Map: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .map
	public func embedValue() -> Value_ {
		.map(self)
	}

	// MARK: Stored properties
	public let elementType: ValueKind
	public let elements: [Value_]

	// MARK: Init

	public init(
		elementType: ValueKind,
		elements: [Value_]
	) throws {
		self.elementType = elementType
		guard elements.allSatisfy({ $0.kind == elementType }) else {
			throw Error.homogeneousMapRequired
		}
		self.elements = elements
	}

	public init(
		elementType: ValueKind,
		@ValuesBuilder buildValues: () throws -> [ValueProtocol]
	) throws {
		try self.init(
			elementType: elementType,
			elements: buildValues().map { $0.embedValue() }
		)
	}

	public init(
		elementType: ValueKind,
		@SpecificValuesBuilder buildValues: () throws -> [Value_]
	) throws {
		try self.init(
			elementType: elementType,
			elements: buildValues()
		)
	}
}

// MARK: Map.Error
public extension Map {
	enum Error: String, Swift.Error, Sendable, Hashable {
		case homogeneousMapRequired
	}
}

public extension Map {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case elements, elementType = "element_type", type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(elements, forKey: .elements)
		try container.encode(elementType, forKey: .elementType)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			elementType: container.decode(ValueKind.self, forKey: .elementType),
			elements: container.decode([Value_].self, forKey: .elements)
		)
	}
}
