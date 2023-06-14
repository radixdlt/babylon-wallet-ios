import Foundation

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .nonFungibleGlobalId
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
		case kind
		case resourceAddress = "resource_address"
		case nonFungibleLocalId = "non_fungible_local_id"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)
		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(nonFungibleLocalId, forKey: .nonFungibleLocalId)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		try self.init(
			resourceAddress: container.decode(ResourceAddress.self, forKey: .resourceAddress),
			nonFungibleLocalId: container.decode(NonFungibleLocalId.self, forKey: .nonFungibleLocalId)
		)
	}
}
