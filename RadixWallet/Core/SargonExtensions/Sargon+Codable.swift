extension ResourceAddress {
	public static let mainnetXRDAddress = Self.xrd(on: .mainnet)
}

// MARK: - NetworkID + Codable
extension NetworkID: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.rawValue)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let discriminant = try container.decode(UInt8.self)
		try self.init(discriminant: discriminant)
	}
}

extension NonFungibleGlobalId {
	public static func fromParts(
		resourceAddress: ResourceAddress,
		nonFungibleLocalId: NonFungibleLocalID
	) -> Self {
		Self(
			resourceAddress: resourceAddress,
			nonFungibleLocalId: nonFungibleLocalId
		)
	}
}
