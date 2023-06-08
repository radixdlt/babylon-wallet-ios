import Foundation

// MARK: - PopFromAuthZone
public struct PopFromAuthZone: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .popFromAuthZone
	public func embed() -> Instruction {
		.popFromAuthZone(self)
	}

	// MARK: Stored properties
	public let proof: Proof

	// MARK: Init

	public init(proof: Proof) {
		self.proof = proof
	}
}

extension PopFromAuthZone {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case intoProof = "into_proof"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(proof, forKey: .intoProof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			proof: container.decode(Proof.self, forKey: .intoProof)
		)
	}
}
