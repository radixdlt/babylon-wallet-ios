// MARK: - KnownEntityAddressesRequest
public struct KnownEntityAddressesRequest: Sendable, Codable, Hashable {
	public let networkId: NetworkID

	public init(
		networkId: NetworkID
	) {
		self.networkId = networkId
	}
}

extension KnownEntityAddressesRequest {
	private enum CodingKeys: String, CodingKey {
		case publicKey = "public_key"
		case networkId = "network_id"
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(String(networkId), forKey: .networkId)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let networkId: UInt8 = try decodeAndConvertToNumericType(container: container, key: .networkId)
		self.init(networkId: NetworkID(networkId))
	}
}

// MARK: - KnownEntityAddressesResponse
public struct KnownEntityAddressesResponse: Sendable, Codable, Hashable {
	public let faucetComponentAddress: ComponentAddress
	public let faucetPackageAddress: PackageAddress
	public let accountPackageAddress: PackageAddress
	public let xrdResourceAddress: ResourceAddress
	public let systemTokenResourceAddress: ResourceAddress
	public let ecdsaSecp256k1TokenResourceAddress: ResourceAddress
	public let eddsaEd25519TokenResourceAddress: ResourceAddress
	public let packageTokenResourceAddress: ResourceAddress
	public let epochManagerSystemAddress: ComponentAddress

	public init(
		faucetComponentAddress: ComponentAddress,
		faucetPackageAddress: PackageAddress,
		accountPackageAddress: PackageAddress,
		xrdResourceAddress: ResourceAddress,
		systemTokenResourceAddress: ResourceAddress,
		ecdsaSecp256k1TokenResourceAddress: ResourceAddress,
		eddsaEd25519TokenResourceAddress: ResourceAddress,
		packageTokenResourceAddress: ResourceAddress,
		epochManagerSystemAddress: ComponentAddress
	) {
		self.faucetComponentAddress = faucetComponentAddress
		self.faucetPackageAddress = faucetPackageAddress
		self.accountPackageAddress = accountPackageAddress
		self.xrdResourceAddress = xrdResourceAddress
		self.systemTokenResourceAddress = systemTokenResourceAddress
		self.ecdsaSecp256k1TokenResourceAddress = ecdsaSecp256k1TokenResourceAddress
		self.eddsaEd25519TokenResourceAddress = eddsaEd25519TokenResourceAddress
		self.packageTokenResourceAddress = packageTokenResourceAddress
		self.epochManagerSystemAddress = epochManagerSystemAddress
	}

	private enum CodingKeys: String, CodingKey {
		case faucetComponentAddress = "faucet_component_address"
		case faucetPackageAddress = "faucet_package_address"
		case accountPackageAddress = "account_package_address"
		case xrdResourceAddress = "xrd_resource_address"
		case systemTokenResourceAddress = "system_token_resource_address"
		case ecdsaSecp256k1TokenResourceAddress = "ecdsa_secp256k1_token_resource_address"
		case eddsaEd25519TokenResourceAddress = "eddsa_ed25519_token_resource_address"
		case packageTokenResourceAddress = "package_token_resource_address"
		case epochManagerSystemAddress = "epoch_manager_system_address"
	}
}

#if DEBUG
extension KnownEntityAddressesResponse {
	public static let previewValue = Self.nebunet
	public static let nebunet = Self(
		faucetComponentAddress: "component_tdx_b_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qdxyth4",
		faucetPackageAddress: "unknown",
		accountPackageAddress: "package_tdx_b_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlssf7lg2",
		xrdResourceAddress: "resource_tdx_b_1qzkcyv5dwq3r6kawy6pxpvcythx8rh8ntum6ws62p95s9hhz9x",
		systemTokenResourceAddress: "unknown",
		ecdsaSecp256k1TokenResourceAddress: "resource_tdx_b_1qzu3wdlw3fx7t82fmt2qme2kpet4g3n2epx02sew49wsp8mlue",
		eddsaEd25519TokenResourceAddress: "resource_tdx_b_1qq8cays25704xdyap2vhgmshkkfyr023uxdtk59ddd4q4zaqlf",
		packageTokenResourceAddress: "unknown",
		epochManagerSystemAddress: "system_tdx_b_1qne8qu4seyvzfgd94p3z8rjcdl3v0nfhv84judpum2lq328939"
	)
}
#endif // DEBUG

public struct InvalidAddressTypeError: Error {
        public let message: String
}

public struct _ResourceAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: String = "resource"
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct _PackageAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: String = "package"
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct _ComponentAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: String = "component"
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct _ClockAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: String = "clock"
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public struct _EpochManagerAddress: Codable, Hashable, Sendable, EntityAddress {
        public static let prefix: String = "epochmanager"
        public var address: String

        public init(address: String) {
                self.address = address
        }
}

public protocol EntityAddress: Codable {
        static var prefix: String { get }
        var address: String { get set}

        init(address: String)
}

extension EntityAddress {
        public init(validatingAddress address: String) throws {
                guard address.hasPrefix(Self.prefix) else {
                        throw InvalidAddressTypeError(message: "Failed to decode \(address), expected prefix: \(Self.prefix)")
                }
                self.init(address: address)
        }

        public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                try self.init(validatingAddress: container.decode(String.self))
        }
}

// MARK: - KnownEntityAddressesResponse
public struct _KnownEntityAddressesResponse: Sendable, Codable, Hashable {
        public let faucetPackageAddress: _PackageAddress
        public let accountPackageAddress: _PackageAddress
        public let xrdResourceAddress: _ResourceAddress
        public let systemTokenResourceAddress: _ResourceAddress
        public let ecdsaSecp256k1TokenResourceAddress: _ResourceAddress
        public let eddsaEd25519TokenResourceAddress: _ResourceAddress
        public let packageTokenResourceAddress: _ResourceAddress
        public let epochManagerSystemAddress: _EpochManagerAddress
        public let clockSystemAddress: _ClockAddress

        public init(
                faucetPackageAddress: _PackageAddress,
                accountPackageAddress: _PackageAddress,
                xrdResourceAddress: _ResourceAddress,
                systemTokenResourceAddress: _ResourceAddress,
                ecdsaSecp256k1TokenResourceAddress: _ResourceAddress,
                eddsaEd25519TokenResourceAddress: _ResourceAddress,
                packageTokenResourceAddress: _ResourceAddress,
                epochManagerSystemAddress: _EpochManagerAddress,
                clockSystemAddress: _ClockAddress
        ) {
                self.faucetPackageAddress = faucetPackageAddress
                self.accountPackageAddress = accountPackageAddress
                self.xrdResourceAddress = xrdResourceAddress
                self.systemTokenResourceAddress = systemTokenResourceAddress
                self.ecdsaSecp256k1TokenResourceAddress = ecdsaSecp256k1TokenResourceAddress
                self.eddsaEd25519TokenResourceAddress = eddsaEd25519TokenResourceAddress
                self.packageTokenResourceAddress = packageTokenResourceAddress
                self.epochManagerSystemAddress = epochManagerSystemAddress
                self.clockSystemAddress = clockSystemAddress
        }

        private enum CodingKeys: String, CodingKey {
                case faucetPackageAddress = "faucet_package_address"
                case accountPackageAddress = "account_package_address"
                case xrdResourceAddress = "xrd_resource_address"
                case systemTokenResourceAddress = "system_token_resource_address"
                case ecdsaSecp256k1TokenResourceAddress = "ecdsa_secp256k1_token_resource_address"
                case eddsaEd25519TokenResourceAddress = "eddsa_ed25519_token_resource_address"
                case packageTokenResourceAddress = "package_token_resource_address"
                case epochManagerSystemAddress = "epoch_manager_system_address"
                case clockSystemAddress = "clock_system_address"
        }
}
