import Foundation

// MARK: - CreateProofFromAuthZoneOfAll
public struct CreateProofFromAuthZoneOfAll: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromAuthZoneOfAll
	public func embed() -> Instruction {
		.createProofFromAuthZoneOfAll(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let intoProof: Proof

	// MARK: Init

	public init(resourceAddress: ResourceAddress, intoProof: Proof) {
		self.resourceAddress = resourceAddress
		self.intoProof = intoProof
	}
}

extension CreateProofFromAuthZoneOfAll {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case resourceAddress = "resource_address"
		case intoProof = "into_proof"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
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
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			intoProof: container.decode(Proof.self, forKey: .intoProof)
		)
	}
}
