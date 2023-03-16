import Foundation

// MARK: - CreateNonFungibleResourceWithOwner
public struct CreateNonFungibleResourceWithOwner: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createNonFungibleResourceWithOwner
	public func embed() -> Instruction {
		.createNonFungibleResourceWithOwner(self)
	}

	// MARK: Stored properties

	public let idType: Enum
	public let metadata: Map_
	public let ownerBadge: NonFungibleGlobalId
	public let initialSupply: Value_

	// MARK: Init

	public init(
		idType: Enum,
		metadata: Map_,
		ownerBadge: NonFungibleGlobalId,
		initialSupply: Value_
	) {
		self.idType = idType
		self.metadata = metadata
		self.ownerBadge = ownerBadge
		self.initialSupply = initialSupply
	}
}

extension CreateNonFungibleResourceWithOwner {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case idType = "id_type"
		case metadata
		case ownerBadge = "owner_badge"
		case initialSupply = "initial_supply"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(idType, forKey: .idType)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(ownerBadge, forKey: .ownerBadge)
		try container.encode(initialSupply, forKey: .initialSupply)
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
		let ownerBadge = try container.decode(NonFungibleGlobalId.self, forKey: .ownerBadge)
		let initialSupply = try container.decode(Value_.self, forKey: .initialSupply)

		self.init(
			idType: idType,
			metadata: metadata,
			ownerBadge: ownerBadge,
			initialSupply: initialSupply
		)
	}
}
