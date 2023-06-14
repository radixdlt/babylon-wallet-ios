import Foundation

// MARK: - SetAuthorityAccessRule
public struct SetAuthorityAccessRule: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setAuthorityAccessRule
	public func embed() -> Instruction {
		.setAuthorityAccessRule(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address
	public let objectKey: Enum
	public let authorityKey: Enum
	public let rule: Enum

	// MARK: Init

	public init(entityAddress: Address, objectKey: Enum, authorityKey: Enum, rule: Enum) {
		self.entityAddress = entityAddress
		self.objectKey = objectKey
		self.authorityKey = authorityKey
		self.rule = rule
	}
}

extension SetAuthorityAccessRule {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entityAddress = "entity_address"
		case objectKey = "object_key"
		case authorityKey = "authority_key"
		case rule
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(entityAddress, forKey: .entityAddress)
		try container.encode(objectKey, forKey: .objectKey)
		try container.encode(authorityKey, forKey: .authorityKey)
		try container.encode(rule, forKey: .rule)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			entityAddress: container.decode(Address.self, forKey: .entityAddress),
			objectKey: container.decode(Enum.self, forKey: .objectKey),
			authorityKey: container.decode(Enum.self, forKey: .authorityKey),
			rule: container.decode(Enum.self, forKey: .rule)
		)
	}
}
