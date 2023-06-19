import Foundation

// MARK: - CreateProofFromAuthZone
public struct CreateProofFromAuthZone: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromAuthZone
	public func embed() -> Instruction {
		.createProofFromAuthZone(self)
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

extension CreateProofFromAuthZone {
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

		try container.encodeValue(resourceAddress, forKey: .resourceAddress)
		try container.encodeValue(intoProof, forKey: .intoProof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decodeValue(forKey: .resourceAddress),
			intoProof: container.decodeValue(forKey: .intoProof)
		)
	}
}
