import Foundation

// MARK: - MintUuidNonFungible
public struct MintUuidNonFungible: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .mintUuidNonFungible
	public func embed() -> Instruction {
		.mintUuidNonFungible(self)
	}

	// MARK: Stored properties

	public let resourceAddress: ResourceAddress
	public let entries: ManifestASTValue

	// MARK: Init

	public init(
		resourceAddress: ResourceAddress,
		entries: ManifestASTValue
	) {
		self.resourceAddress = resourceAddress
		self.entries = entries
	}
}

extension MintUuidNonFungible {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case entries
		case resourceAddress = "resource_address"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(entries, forKey: .entries)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			entries: container.decode(ManifestASTValue.self, forKey: .entries)
		)
	}
}
