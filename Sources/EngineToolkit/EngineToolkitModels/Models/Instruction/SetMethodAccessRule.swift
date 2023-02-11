import Foundation

// MARK: - SetMethodAccessRule
public struct SetMethodAccessRule: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setMethodAccessRule
	public func embed() -> Instruction {
		.setMethodAccessRule(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address
	public let index: UInt32
	public let key: Enum
	public let rule: Enum

	// MARK: Init

	public init(entityAddress: Address, index: UInt32, key: Enum, rule: Enum) {
		self.entityAddress = entityAddress
		self.index = index
		self.key = key
		self.rule = rule
	}
}

extension SetMethodAccessRule {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entityAddress = "entity_address"
		case key
		case rule
		case index
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(entityAddress, forKey: .entityAddress)
		try container.encode(index.proxyEncodable, forKey: .index)
		try container.encode(key, forKey: .key)
		try container.encode(rule, forKey: .rule)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let entityAddress = try container.decode(Address.self, forKey: .entityAddress)
		let index = try container.decode(UInt32.ProxyDecodable.self, forKey: .index).decoded
		let key = try container.decode(Enum.self, forKey: .key)
		let rule = try container.decode(Enum.self, forKey: .rule)

		self.init(entityAddress: entityAddress, index: index, key: key, rule: rule)
	}
}
