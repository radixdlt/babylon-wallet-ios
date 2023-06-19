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
	public let consensusManagerComponentAddress: ComponentAddress

	public init(
		faucetComponentAddress: ComponentAddress,
		faucetPackageAddress: PackageAddress,
		accountPackageAddress: PackageAddress,
		xrdResourceAddress: ResourceAddress,
		systemTokenResourceAddress: ResourceAddress,
		ecdsaSecp256k1TokenResourceAddress: ResourceAddress,
		eddsaEd25519TokenResourceAddress: ResourceAddress,
		packageTokenResourceAddress: ResourceAddress,
		consensusManagerComponentAddress: ComponentAddress
	) {
		self.faucetComponentAddress = faucetComponentAddress
		self.faucetPackageAddress = faucetPackageAddress
		self.accountPackageAddress = accountPackageAddress
		self.xrdResourceAddress = xrdResourceAddress
		self.systemTokenResourceAddress = systemTokenResourceAddress
		self.ecdsaSecp256k1TokenResourceAddress = ecdsaSecp256k1TokenResourceAddress
		self.eddsaEd25519TokenResourceAddress = eddsaEd25519TokenResourceAddress
		self.packageTokenResourceAddress = packageTokenResourceAddress
		self.consensusManagerComponentAddress = consensusManagerComponentAddress
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
		case consensusManagerComponentAddress = "consensus_manager_component_address"
	}
}

#if DEBUG
extension KnownEntityAddressesResponse {
	public static let previewValue = Self.nebunet
	public static let nebunet = Self(
		faucetComponentAddress: try! .init(validatingAddress: "component_tdx_22_1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxrcppq4"),
		faucetPackageAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxfaucetxxxxxxxxx000034355863xxxxxxxxxuy7qln"),
		accountPackageAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxaccntxxxxxxxxxx000929625493xxxxxxxxxgp6td7"),
		xrdResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxmaesev"),
		systemTokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxsystxnxxxxxxxxx002683325037xxxxxxxxxgyyauj"),
		ecdsaSecp256k1TokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxed25sgxxxxxxxxx002236757237xxxxxxxxxpd7z2f"),
		eddsaEd25519TokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxsecpsgxxxxxxxxx004638826440xxxxxxxxxgevh2f"),
		packageTokenResourceAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxresrcexxxxxxxxx000538436477xxxxxxxxxkqjm7p"),
		consensusManagerComponentAddress: try! .init(validatingAddress: "component_tdx_22_1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxrcppq4")
	)
}
#endif // DEBUG
