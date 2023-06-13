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
	/*
	 {
	   "xrd": "resource_tdx_22_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxmaesev",
	   "secp256k1_signature_virtual_badge": "resource_tdx_22_1nfxxxxxxxxxxsecpsgxxxxxxxxx004638826440xxxxxxxxxgevh2f",
	   "ed25519_signature_virtual_badge": "resource_tdx_22_1nfxxxxxxxxxxed25sgxxxxxxxxx002236757237xxxxxxxxxpd7z2f",
	   "package_of_direct_caller_virtual_badge": "resource_tdx_22_1nfxxxxxxxxxxpkcllrxxxxxxxxx003652646977xxxxxxxxxekvf9z",
	   "global_caller_virtual_badge": "resource_tdx_22_1nfxxxxxxxxxxglcllrxxxxxxxxx002350006550xxxxxxxxxslvf9z",
	   "system_transaction_badge": "resource_tdx_22_1nfxxxxxxxxxxsystxnxxxxxxxxx002683325037xxxxxxxxxgyyauj",
	   "package_owner_badge": "resource_tdx_22_1nfxxxxxxxxxxpkgwnrxxxxxxxxx002558553505xxxxxxxxxekucfz",
	   "validator_owner_badge": "resource_tdx_22_1nfxxxxxxxxxxvdrwnrxxxxxxxxx004365253834xxxxxxxxx5dhcfz",
	   "account_owner_badge": "resource_tdx_22_1nfxxxxxxxxxxaccwnrxxxxxxxxx006664022062xxxxxxxxx9cvcfz",
	   "identity_owner_badge": "resource_tdx_22_1nfxxxxxxxxxxdntwnrxxxxxxxxx002876444928xxxxxxxxx4nlcfz",
	   "package_package": "package_tdx_22_1pkgxxxxxxxxxpackgexxxxxxxxx000726633226xxxxxxxxx5y6wwp",
	   "resource_package": "package_tdx_22_1pkgxxxxxxxxxresrcexxxxxxxxx000538436477xxxxxxxxxkqjm7p",
	   "account_package": "package_tdx_22_1pkgxxxxxxxxxaccntxxxxxxxxxx000929625493xxxxxxxxxgp6td7",
	   "identity_package": "package_tdx_22_1pkgxxxxxxxxxdntyxxxxxxxxxxx008560783089xxxxxxxxxc2fuq7",
	   "epoch_manager_package": "package_tdx_22_1pkgxxxxxxxxxepchmgxxxxxxxxx000797223725xxxxxxxxxvc60as",
	   "clock_package": "package_tdx_22_1pkgxxxxxxxxxclckxxxxxxxxxxx000577344478xxxxxxxxxdx6wq7",
	   "access_controller_package": "package_tdx_22_1pkgxxxxxxxxxcntrlrxxxxxxxxx000648572295xxxxxxxxxd2fmem",
	   "transaction_processor_package": "package_tdx_22_1pkgxxxxxxxxxtxnpxrxxxxxxxxx002962227406xxxxxxxxx7l3eqm",
	   "metadata_module_package": "package_tdx_22_1pkgxxxxxxxxxmtdataxxxxxxxxx005246577269xxxxxxxxxwj09d9",
	   "royalty_module_package": "package_tdx_22_1pkgxxxxxxxxxryaltyxxxxxxxxx003849573396xxxxxxxxxkal8du",
	   "access_rules_package": "package_tdx_22_1pkgxxxxxxxxxarulesxxxxxxxxx002304462983xxxxxxxxxg678lg",
	   "genesis_helper_package": "package_tdx_22_1pkgxxxxxxxxxgenssxxxxxxxxxx004372642773xxxxxxxxxaq3gk7",
	   "faucet_package": "package_tdx_22_1pkgxxxxxxxxxfaucetxxxxxxxxx000034355863xxxxxxxxxuy7qln",
	   "epoch_manager": "epochmanager_tdx_22_1sexxxxxxxxxxephmgrxxxxxxxxx009352500589xxxxxxxxx9j68zk",
	   "clock": "clock_tdx_22_1skxxxxxxxxxxclckxxxxxxxxxxx002253583992xxxxxxxxxutwtm5",
	   "genesis_helper": "component_tdx_22_1cptxxxxxxxxxgenssxxxxxxxxxx000977302539xxxxxxxxxzuwffc",
	   "faucet": "component_tdx_22_1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxrcppq4"
	 }
	 */
	public let faucetComponentAddress: ComponentAddress
	public let faucetPackageAddress: PackageAddress
	public let accountPackageAddress: PackageAddress
	public let xrdResourceAddress: ResourceAddress
	public let systemTokenResourceAddress: ResourceAddress
	public let ecdsaSecp256k1TokenResourceAddress: ResourceAddress
	public let eddsaEd25519TokenResourceAddress: ResourceAddress
	public let packageTokenResourceAddress: PackageAddress
	public let epochManagerSystemAddress: ComponentAddress

	public init(
		faucetComponentAddress: ComponentAddress,
		faucetPackageAddress: PackageAddress,
		accountPackageAddress: PackageAddress,
		xrdResourceAddress: ResourceAddress,
		systemTokenResourceAddress: ResourceAddress,
		ecdsaSecp256k1TokenResourceAddress: ResourceAddress,
		eddsaEd25519TokenResourceAddress: ResourceAddress,
		packageTokenResourceAddress: PackageAddress,
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
		faucetComponentAddress: try! .init(validatingAddress: "component_tdx_22_1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxrcppq4"),
		faucetPackageAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxfaucetxxxxxxxxx000034355863xxxxxxxxxuy7qln"),
		accountPackageAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxaccntxxxxxxxxxx000929625493xxxxxxxxxgp6td7"),
		xrdResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxmaesev"),
		systemTokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxsystxnxxxxxxxxx002683325037xxxxxxxxxgyyauj"),
		ecdsaSecp256k1TokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxed25sgxxxxxxxxx002236757237xxxxxxxxxpd7z2f"),
		eddsaEd25519TokenResourceAddress: try! .init(validatingAddress: "resource_tdx_22_1nfxxxxxxxxxxsecpsgxxxxxxxxx004638826440xxxxxxxxxgevh2f"),
		packageTokenResourceAddress: try! .init(validatingAddress: "package_tdx_22_1pkgxxxxxxxxxresrcexxxxxxxxx000538436477xxxxxxxxxkqjm7p"),
		epochManagerSystemAddress: try! .init(validatingAddress: "component_tdx_22_1cptxxxxxxxxxfaucetxxxxxxxxx000527798379xxxxxxxxxrcppq4")
	)
}
#endif // DEBUG
