import Foundation

// MARK: - RemoveMetadata
public struct RemoveMetadata: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .removeMetadata
	public func embed() -> Instruction {
		.removeMetadata(self)
	}

	// MARK: Stored properties

	public let entityAddress: Address_ // TODO:  What should this actually be?
	public let key: String

	// MARK: Init

	public init(entityAddress: Address_, key: String) {
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

		try container.encode(entityAddress, forKey: .entityAddress)
		try container.encode(key.proxyEncodable, forKey: .key)
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
			key: container.decode(String.ProxyDecodable.self, forKey: .key).decoded
		)
	}
}
