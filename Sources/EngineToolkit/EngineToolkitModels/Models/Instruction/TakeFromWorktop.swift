import Foundation

// MARK: - TakeFromWorktop
public struct TakeFromWorktop: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .takeFromWorktop
	public func embed() -> Instruction {
		.takeFromWorktop(self)
	}

	// MARK: Stored properties
	/// Temporary, will change to `Address`. This can actually only be either `ResourceAddress` or `Address_`.
	public let resourceAddress: Value_
	public let bucket: Bucket

	// MARK: Init

	public init(resourceAddress: ResourceAddress, bucket: Bucket) {
		self.resourceAddress = .resourceAddress(resourceAddress)
		self.bucket = bucket
	}

	public init(resourceAddress: Address_, bucket: Bucket) {
		self.resourceAddress = .address(resourceAddress)
		self.bucket = bucket
	}
}

extension TakeFromWorktop {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case resourceAddress = "resource_address"
		case intoBucket = "into_bucket"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(bucket, forKey: .intoBucket)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.resourceAddress = try container.decode(Value_.self, forKey: .resourceAddress)
		self.bucket = try container.decode(Bucket.self, forKey: .intoBucket)
	}
}
