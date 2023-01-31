import Foundation

// MARK: - CreateProofFromBucket
public struct CreateProofFromBucket: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromBucket
	public func embed() -> Instruction {
		.createProofFromBucket(self)
	}

	// MARK: Stored properties

	public let bucket: Bucket
	public let proof: Proof

	// MARK: Init

	public init(bucket: Bucket, proof: Proof) {
		self.bucket = bucket
		self.proof = proof
	}
}

public extension CreateProofFromBucket {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case bucket
		case intoProof = "into_proof"
	}

	// MARK: Codable

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bucket, forKey: .bucket)
		try container.encode(proof, forKey: .intoProof)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		let bucket = try container.decode(Bucket.self, forKey: .bucket)
		let proof = try container.decode(Proof.self, forKey: .intoProof)

		self.init(bucket: bucket, proof: proof)
	}
}
