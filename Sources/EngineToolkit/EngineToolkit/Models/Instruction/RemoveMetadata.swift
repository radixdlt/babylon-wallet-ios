import Foundation

// MARK: - RemoveMetadata
public struct RemoveMetadata: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .removeMetadata
	public func embed() -> Instruction {
		.removeMetadata(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address
	public let key: String

	// MARK: Init

	public init(entityAddress: Address, key: String) {
		self.entityAddress = entityAddress
		self.key = key
	}
}

extension RemoveMetadata {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entityAddress = "entity_address"
		case key
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(entityAddress, forKey: .entityAddress)
		try container.encodeValue(key, forKey: .key)
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
			key: container.decodeValue(forKey: .key)
		)
	}
}
