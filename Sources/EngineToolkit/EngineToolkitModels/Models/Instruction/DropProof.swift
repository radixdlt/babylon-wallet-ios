import Foundation

// MARK: - DropProof
public struct DropProof: InstructionProtocol, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .dropProof
	public func embed() -> Instruction {
		.dropProof(self)
	}

	// MARK: Stored properties
	public let proof: Proof

	// MARK: Init

	public init(_ proof: Proof) {
		self.proof = proof
	}

	public init(integerLiteral value: Proof.IntegerLiteralType) {
		self.init(Proof(integerLiteral: value))
	}

	public init(stringLiteral value: Proof.StringLiteralType) {
		self.init(Proof(stringLiteral: value))
	}
}

extension DropProof {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case proof
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(proof, forKey: .proof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(container.decode(Proof.self, forKey: .proof))
	}
}
