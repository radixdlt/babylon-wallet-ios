import Foundation

// MARK: - TakeFromWorktopByIds
public struct TakeFromWorktopByIds: InstructionProtocol {
	// Type name, used as a discriminator
	public static let kind: InstructionKind = .takeFromWorktopByIds
	public func embed() -> Instruction {
		.takeFromWorktopByIds(self)
	}

	// MARK: Stored properties
	public let resourceAddress: Address_
	public let ids: Set<NonFungibleLocalId>
	public let bucket: Bucket

	// MARK: Init

	// Same order as scrypto: IDS, Address, Bucket
	public init(
		_ ids: Set<NonFungibleLocalId>,
		resourceAddress: ResourceAddress,
		bucket: Bucket
	) {
		self.resourceAddress = resourceAddress.asGeneral
		self.ids = ids
		self.bucket = bucket
	}
}

extension TakeFromWorktopByIds {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type = "instruction"
		case ids
		case resourceAddress = "resource_address"
		case intoBucket = "into_bucket"
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(ids, forKey: .ids)
		try container.encode(bucket, forKey: .intoBucket)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: InstructionKind = try container.decode(InstructionKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.instructionTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			container.decode(Set<NonFungibleLocalId>.self, forKey: .ids),
			resourceAddress: container.decode(Address_.self, forKey: .resourceAddress).asSpecific(),
			bucket: container.decode(Bucket.self, forKey: .intoBucket)
		)
	}
}
