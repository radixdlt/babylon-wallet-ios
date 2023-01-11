import Foundation

// MARK: - NonFungibleAddress
public struct NonFungibleAddress: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .nonFungibleAddress
	public func embedValue() -> Value_ {
		.nonFungibleAddress(self)
	}

	// MARK: Stored properties
	public let resourceAddress: ResourceAddress
	public let nonFungibleId: NonFungibleId

	// MARK: Init

	public init(resourceAddress: ResourceAddress, nonFungibleId: NonFungibleId) {
		self.resourceAddress = resourceAddress
		self.nonFungibleId = nonFungibleId
	}
}

public extension NonFungibleAddress {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case type
		case resourceAddress = "resource_address"
		case nonFungibleId = "non_fungible_id"
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)
		try container.encode(resourceAddress, forKey: .resourceAddress)
		try container.encode(nonFungibleId, forKey: .nonFungibleId)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self.init(
			resourceAddress: try container.decode(ResourceAddress.self, forKey: .resourceAddress),
			nonFungibleId: try container.decode(NonFungibleId.self, forKey: .nonFungibleId)
		)
	}
}
