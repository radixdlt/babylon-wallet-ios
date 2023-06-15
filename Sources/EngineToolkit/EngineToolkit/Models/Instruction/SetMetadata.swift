import Foundation

// MARK: - SetMetadata
public struct SetMetadata: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setMetadata
	public func embed() -> Instruction {
		.setMetadata(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address
	public let key: String
	public let value: Enum

	// MARK: Init

	public init(entityAddress: Address, key: String, value: Enum) {
		self.entityAddress = entityAddress
		self.key = key
		self.value = value
	}

	public init(accountAddress: AccountAddress, key: String, value: Enum) {
		self.entityAddress = accountAddress.asGeneral()
		self.key = key
		self.value = value
	}
}

extension SetMetadata {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entityAddress = "entity_address"
		case key
		case value
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(entityAddress, forKey: .entityAddress)
		try container.encodeValue(key, forKey: .key)
		try container.encodeValue(value, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			entityAddress: container.decodeValue(forKey: .entityAddress),
			key: container.decodeValue(forKey: .key),
			value: container.decodeValue(forKey: .value)
		)
	}
}

extension KeyedDecodingContainer {
	func decodeValue<V: ValueProtocol>(forKey key: KeyedDecodingContainer<K>.Key) throws -> V {
		try .extractValue(from: decode(ManifestASTValue.self, forKey: key))
	}

	func decodeValue<V: ValueProtocol>(forKey key: KeyedDecodingContainer<K>.Key) throws -> Set<V> {
		try Set(decode(Set<ManifestASTValue>.self, forKey: key).map {
			try V.extractValue(from: $0)
		})
	}
}

extension KeyedEncodingContainer {
	mutating func encodeValue<V: ValueProtocol>(_ value: V, forKey key: KeyedEncodingContainer<K>.Key) throws {
		try encode(value.embedValue(), forKey: key)
	}

	mutating func encodeValue<V: ValueProtocol>(_ value: any Collection<V>, forKey key: KeyedEncodingContainer<K>.Key) throws {
		try encode(value.map { $0.embedValue() }, forKey: key)
	}
}
