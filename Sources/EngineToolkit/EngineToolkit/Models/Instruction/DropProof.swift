import Foundation

// MARK: - DropProof
public struct DropProof: InstructionProtocol, ExpressibleByStringLiteral {
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

	public init(stringLiteral value: StringLiteralType) {
		self.init(Proof(value))
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

		try container.encodeValue(proof, forKey: .proof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			container.decodeValue(forKey: .proof)
		)
	}
}
