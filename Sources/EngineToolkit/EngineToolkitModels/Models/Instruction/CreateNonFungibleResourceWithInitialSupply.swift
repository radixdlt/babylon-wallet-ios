import Foundation

// MARK: - CreateNonFungibleResourceWithInitialSupply
public struct CreateNonFungibleResourceWithInitialSupply: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createNonFungibleResourceWithInitialSupply
	public func embed() -> Instruction {
		.createNonFungibleResourceWithInitialSupply(self)
	}

	// MARK: Stored properties

	public let idType: Enum
	public let metadata: Map_
	public let accessRules: Map_
	public let initialSupply: ManifestASTValue

	// MARK: Init

	public init(
		idType: Enum,
		metadata: Map_,
		accessRules: Map_,
		initialSupply: ManifestASTValue
	) {
		self.idType = idType
		self.metadata = metadata
		self.accessRules = accessRules
		self.initialSupply = initialSupply
	}
}

extension CreateNonFungibleResourceWithInitialSupply {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case idType = "id_type"
		case metadata
		case accessRules = "access_rules"
		case initialSupply = "initial_supply"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(idType, forKey: .idType)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(accessRules, forKey: .accessRules)
		try container.encode(initialSupply, forKey: .initialSupply)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			idType: container.decode(Enum.self, forKey: .idType),
			metadata: container.decode(Map_.self, forKey: .metadata),
			accessRules: container.decode(Map_.self, forKey: .accessRules),
			initialSupply: container.decode(ManifestASTValue.self, forKey: .initialSupply)
		)
	}
}
