import Foundation

// MARK: - TakeAllFromWorktop
public struct TakeAllFromWorktop: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .takeAllFromWorktop
	public func embed() -> Instruction {
		.takeAllFromWorktop(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let bucket: Bucket

	// MARK: Init

	public init(resourceAddress: ResourceAddress, bucket: Bucket) {
		self.resourceAddress = resourceAddress
		self.bucket = bucket
	}
}

extension TakeAllFromWorktop {
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

		try container.encodeValue(resourceAddress, forKey: .resourceAddress)
		try container.encodeValue(bucket, forKey: .intoBucket)
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
			bucket: container.decodeValue(forKey: .intoBucket)
		)
	}
}
