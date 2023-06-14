import Foundation

// MARK: - CreateProofFromBucketOfAmount
public struct CreateProofFromBucketOfAmount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromBucketOfAmount
	public func embed() -> Instruction {
		.createProofFromBucketOfAmount(self)
	}

	// MARK: Stored properties

	public let bucket: Bucket
	public let amount: Decimal_
	public let proof: Proof

	// MARK: Init

	public init(bucket: Bucket, amount: Decimal_, proof: Proof) {
		self.bucket = bucket
		self.amount = amount
		self.proof = proof
	}
}

extension CreateProofFromBucketOfAmount {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case bucket
		case amount
		case intoProof = "into_proof"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bucket, forKey: .bucket)
		try container.encode(amount, forKey: .amount)
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
			bucket: container.decode(Bucket.self, forKey: .bucket),
			amount: container.decode(Decimal_.self, forKey: .amount),
			proof: container.decode(Proof.self, forKey: .intoProof)
		)
	}
}
