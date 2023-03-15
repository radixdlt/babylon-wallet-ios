import Foundation

// MARK: - TakeFromWorktopByAmount
public struct TakeFromWorktopByAmount: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .takeFromWorktopByAmount
	public func embed() -> Instruction {
		.takeFromWorktopByAmount(self)
	}

	// MARK: Stored properties
	public let amount: Decimal_
	/// Temporary, will change to `Address`. This can actually only be either `ResourceAddress` or `Address_`.
	public let resourceAddress: ManifestASTValue
	public let bucket: Bucket

	// MARK: Init

	// Using same order as Scrypto uses, AMOUNT, ADDRESS, BUCKET
	public init(
		amount: Decimal_,
		resourceAddress: ResourceAddress,
		bucket: Bucket
	) {
		self.amount = amount
		self.resourceAddress = .resourceAddress(resourceAddress)
		self.bucket = bucket
	}

	public init(
		amount: Decimal_,
		resourceAddress: Address_,
		bucket: Bucket
	) {
		self.amount = amount
		self.resourceAddress = .address(resourceAddress)
		self.bucket = bucket
	}
}

extension TakeFromWorktopByAmount {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case amount
		case resourceAddress = "resource_address"
		case intoBucket = "into_bucket"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(amount, forKey: .amount)
		try container.encode(bucket, forKey: .intoBucket)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.resourceAddress = try container.decode(ManifestASTValue.self, forKey: .resourceAddress)
		self.amount = try container.decode(Decimal_.self, forKey: .amount)
		self.bucket = try container.decode(Bucket.self, forKey: .intoBucket)
	}
}
