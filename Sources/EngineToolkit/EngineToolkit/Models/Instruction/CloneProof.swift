import Foundation

// MARK: - CloneProof
public struct CloneProof: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .cloneProof
	public func embed() -> Instruction {
		.cloneProof(self)
	}

	// MARK: Stored properties
	public let source: Proof
	public let target: Proof

	// MARK: Init

	public init(from source: Proof, to target: Proof) {
		self.source = source
		self.target = target
	}
}

extension CloneProof {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case proof
		case intoProof = "into_proof"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encodeValue(source, forKey: .proof)
		try container.encodeValue(target, forKey: .intoProof)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			from: container.decodeValue(forKey: .proof),
			to: container.decodeValue(forKey: .intoProof)
		)
	}
}
