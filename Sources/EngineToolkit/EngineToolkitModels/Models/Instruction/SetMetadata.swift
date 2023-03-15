import Foundation

// MARK: - SetMetadata
public struct SetMetadata: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .setMetadata
	public func embed() -> Instruction {
		.setMetadata(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address_ // TODO:  What should this actually be?
	public let key: String
	public let value: String

	// MARK: Init

	public init(entityAddress: Address_, key: String, value: String) {
		self.entityAddress = entityAddress
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

		try container.encode(entityAddress, forKey: .entityAddress)
		try container.encode(key.proxyEncodable, forKey: .key)
		try container.encode(value.proxyEncodable, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			entityAddress: container.decode(Address_.self, forKey: .entityAddress),
			key: container.decode(String.ProxyDecodable.self, forKey: .key).decoded,
			value: container.decode(String.ProxyDecodable.self, forKey: .value).decoded
		)
	}
}
