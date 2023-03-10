import Foundation

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .nonFungibleGlobalId
	public func embedValue() -> ManifestASTValue {
		.nonFungibleGlobalId(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let nonFungibleLocalId: NonFungibleLocalId

	// MARK: Init

	public init(resourceAddress: ResourceAddress, nonFungibleLocalId: NonFungibleLocalId) {
		self.resourceAddress = resourceAddress
		self.nonFungibleLocalId = nonFungibleLocalId
	}
}

extension NonFungibleGlobalId {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type
		case resourceAddress = "resource_address"
		case nonFungibleLocalId = "non_fungible_local_id"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(nonFungibleLocalId, forKey: .nonFungibleLocalId)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			nonFungibleLocalId: container.decode(NonFungibleLocalId.self, forKey: .nonFungibleLocalId)
		)
	}
}
