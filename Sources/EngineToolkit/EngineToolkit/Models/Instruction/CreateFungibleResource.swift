import Foundation

// MARK: - CreateFungibleResource
public struct CreateFungibleResource: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createFungibleResource
	public func embed() -> Instruction {
		.createFungibleResource(self)
	}

	// MARK: Stored properties

	public let divisibility: UInt8
	public let metadata: Map_
	public let accessRules: Map_

	// MARK: Init

	public init(
		divisibility: UInt8,
		metadata: Map_,
		accessRules: Map_
	) {
		self.divisibility = divisibility
		self.metadata = metadata
		self.accessRules = accessRules
	}
}

extension CreateFungibleResource {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case divisibility
		case metadata
		case accessRules = "access_rules"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(divisibility, forKey: .divisibility)
		try container.encodeValue(metadata, forKey: .metadata)
		try container.encodeValue(accessRules, forKey: .accessRules)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			divisibility: container.decodeValue(forKey: .divisibility),
			metadata: container.decodeValue(forKey: .metadata),
			accessRules: container.decodeValue(forKey: .accessRules)
		)
	}
}
