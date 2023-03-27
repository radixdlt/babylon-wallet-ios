import Foundation

// MARK: - CreateProofFromAuthZoneByIds
public struct CreateProofFromAuthZoneByIds: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromAuthZoneByIds
	public func embed() -> Instruction {
		.createProofFromAuthZoneByIds(self)
	}

	// MARK: Stored properties
	public let resourceAddress: Address_
	public let ids: Set<NonFungibleLocalId>
	public let intoProof: Proof

	// MARK: Init

	public init(
		resourceAddress: ResourceAddress,
		ids: Set<NonFungibleLocalId>,
		intoProof: Proof
	) {
		self.resourceAddress = resourceAddress.asGeneral
		self.ids = ids
		self.intoProof = intoProof
	}
}

extension CreateProofFromAuthZoneByIds {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case ids
		case resourceAddress = "resource_address"
		case intoProof = "into_proof"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(ids, forKey: .ids)
		try container.encode(intoProof, forKey: .intoProof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decode(Address_.self, forKey: .resourceAddress).asSpecific(),
			ids: container.decode(Set<NonFungibleLocalId>.self, forKey: .ids),
			intoProof: container.decode(Proof.self, forKey: .intoProof)
		)
	}
}
