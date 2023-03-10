import Foundation

// MARK: - AssertWorktopContainsByIds
public struct AssertWorktopContainsByIds: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .assertWorktopContainsByIds
	public func embed() -> Instruction {
		.assertWorktopContainsByIds(self)
	}

	// MARK: Stored properties
	/// Temporary, will change to `Address`. This can actually only be either `ResourceAddress` or `Address_`.
	public let resourceAddress: ManifestASTValue
	public let ids: Set<NonFungibleLocalId>

	// MARK: Init

	public init(resourceAddress: ResourceAddress, ids: Set<NonFungibleLocalId>) {
		self.resourceAddress = .resourceAddress(resourceAddress)
		self.ids = ids
	}

	public init(resourceAddress: Address_, ids: Set<NonFungibleLocalId>) {
		self.resourceAddress = .address(resourceAddress)
		self.ids = ids
	}
}

extension AssertWorktopContainsByIds {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case ids
		case resourceAddress = "resource_address"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(ids, forKey: .ids)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.resourceAddress = try container.decode(ManifestASTValue.self, forKey: .resourceAddress)
		self.ids = try container.decode(Set<NonFungibleLocalId>.self, forKey: .ids)
	}
}
