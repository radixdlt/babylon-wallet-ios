// MARK: - Decimal192 + Codable
extension Decimal192: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		try self.init(string)
	}
}

extension AddressProtocol where Self: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		try self.init(validatingAddress: string)
	}
}

// MARK: - AccountAddress + Codable
extension AccountAddress: Codable {}

// MARK: - IdentityAddress + Codable
extension IdentityAddress: Codable {}

// MARK: - ResourceAddress + Codable
extension ResourceAddress: Codable {}

// MARK: - PoolAddress + Codable
extension PoolAddress: Codable {}

// MARK: - ValidatorAddress + Codable
extension ValidatorAddress: Codable {}

// MARK: - PackageAddress + Codable
extension PackageAddress: Codable {}

extension ResourceAddress {
	public static let mainnetXRDAddress = Self.xrd(on: .mainnet)
}

extension TransactionManifest {
	public var involvedPoolAddresses: [PoolAddress] {
		fatalError("Sargon migration")
	}
}

// MARK: - NonFungibleLocalId + Codable
extension NonFungibleLocalId: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.description)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let string = try container.decode(String.self)
		//        try self.init(localId: string)
		fatalError("Sargon migration: use `self.init(localId: string)`")
	}
}

extension Decimal192 {
	public var isZero: Bool {
		self == .zero
	}
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
