import Foundation

// MARK: - CreateFungibleResourceWithOwner
public struct CreateFungibleResourceWithOwner: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createFungibleResourceWithOwner
	public func embed() -> Instruction {
		.createFungibleResourceWithOwner(self)
	}

	// MARK: Stored properties

	public let divisibility: UInt8
	public let metadata: Map_
	public let ownerBadge: NonFungibleGlobalId
	public let initialSupply: Value_

	// MARK: Init

	public init(
		divisibility: UInt8,
		metadata: Map_,
		ownerBadge: NonFungibleGlobalId,
		initialSupply: Value_
	) {
		self.divisibility = divisibility
		self.metadata = metadata
		self.ownerBadge = ownerBadge
		self.initialSupply = initialSupply
	}
}

public extension CreateFungibleResourceWithOwner {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case divisibility
		case metadata
		case ownerBadge = "owner_badge"
		case initialSupply = "initial_supply"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(divisibility.proxyEncodable, forKey: .divisibility)
		try container.encode(metadata, forKey: .metadata)
		try container.encode(ownerBadge, forKey: .ownerBadge)
		try container.encode(initialSupply, forKey: .initialSupply)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let divisibility = try container.decode(UInt8.ProxyDecodable.self, forKey: .divisibility).decoded
		let metadata = try container.decode(Map_.self, forKey: .metadata)
		let ownerBadge = try container.decode(NonFungibleGlobalId.self, forKey: .ownerBadge)
		let initialSupply = try container.decode(Value_.self, forKey: .initialSupply)

		self.init(
			divisibility: divisibility,
			metadata: metadata,
			ownerBadge: ownerBadge,
			initialSupply: initialSupply
		)
	}
}
