import Foundation

// MARK: - Map_
public struct Map_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .map
	public func embedValue() -> Value_ {
		.map(self)
	}

	// MARK: Stored properties

	public let keyValueKind: ValueKind
	public let valueValueKind: ValueKind
	public let entries: [[Value_]]
	//    public let entries: [(Value_, Value_)]

	// MARK: Init

	public init(
		keyValueKind: ValueKind,
		valueValueKind: ValueKind,
		entries: [[Value_]]
	) throws {
		self.keyValueKind = keyValueKind
		self.valueValueKind = valueValueKind
		self.entries = entries
	}
}

// MARK: Map_.Error
public extension Map_ {
	enum Error: String, Swift.Error, Sendable, Hashable {
		case homogeneousMapRequired
	}
}

public extension Map_ {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
		case entries
		case keyValueKind = "key_value_kind"
		case valueValueKind = "value_value_kind"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(keyValueKind, forKey: .keyValueKind)
		try container.encode(valueValueKind, forKey: .valueValueKind)
		try container.encode(entries, forKey: .entries) // TODO: Fix map
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let entries = try container.decode([[Value_]].self, forKey: .entries)
		let keyValueKind = try container.decode(ValueKind.self, forKey: .keyValueKind)
		let valueValueKind = try container.decode(ValueKind.self, forKey: .valueValueKind)

		try self.init(
			keyValueKind: keyValueKind, valueValueKind: valueValueKind, entries: entries
		)
	}
}
