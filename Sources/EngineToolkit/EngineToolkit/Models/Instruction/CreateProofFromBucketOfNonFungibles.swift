import Foundation

// MARK: - CreateProofFromBucketOfNonFungibles
public struct CreateProofFromBucketOfNonFungibles: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .createProofFromBucketOfNonFungibles
	public func embed() -> Instruction {
		.createProofFromBucketOfNonFungibles(self)
	}

	// MARK: Stored properties

	public let bucket: Bucket
	public let ids: Set<NonFungibleLocalId>
	public let proof: Proof

	// MARK: Init

	public init(
		bucket: Bucket,
		ids: Set<NonFungibleLocalId>,
		proof: Proof
	) {
		self.bucket = bucket
		self.ids = ids
		self.proof = proof
	}
}

extension CreateProofFromBucketOfNonFungibles {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case bucket
		case ids
		case intoProof = "into_proof"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(bucket, forKey: .bucket)
		try container.encode(ids, forKey: .ids)
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
			ids: container.decode(Set<NonFungibleLocalId>.self, forKey: .ids),
			proof: container.decode(Proof.self, forKey: .intoProof)
		)
	}
}
