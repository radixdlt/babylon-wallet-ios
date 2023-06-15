import CasePaths
import Foundation

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .nonFungibleGlobalId
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.nonFungibleGlobalId

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
		case resourceAddress = "resource_address"
		case nonFungibleLocalId = "non_fungible_local_id"
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encodeValue(resourceAddress, forKey: .resourceAddress)
		try container.encodeValue(nonFungibleLocalId, forKey: .nonFungibleLocalId)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Extract address?
		try self.init(
			resourceAddress: container.decodeValue(forKey: .resourceAddress),
			nonFungibleLocalId: container.decodeValue(forKey: .nonFungibleLocalId)
		)
	}
}
