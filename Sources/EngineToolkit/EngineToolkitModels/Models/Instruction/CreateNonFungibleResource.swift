import Foundation

// MARK: - CreateNonFungibleResource
public struct CreateNonFungibleResource: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createNonFungibleResource
	public func embed() -> Instruction {
		.createNonFungibleResource(self)
	}

	// MARK: Stored properties

	public let idType: Enum
	public let metadata: Map_
	public let accessRules: Map_

	// MARK: Init

	public init(
		idType: Enum,
		metadata: Map_,
		accessRules: Map_
	) {
		self.idType = idType
		self.metadata = metadata
		self.accessRules = accessRules
	}
}

extension CreateNonFungibleResource {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case idType = "id_type"
		case metadata
		case accessRules = "access_rules"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(idType, forKey: .idType)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(accessRules, forKey: .accessRules)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let idType = try container.decode(Enum.self, forKey: .idType)
		let metadata = try container.decode(Map_.self, forKey: .metadata)
		let accessRules = try container.decode(Map_.self, forKey: .accessRules)

		self.init(
			idType: idType,
			metadata: metadata,
			accessRules: accessRules
		)
	}
}
