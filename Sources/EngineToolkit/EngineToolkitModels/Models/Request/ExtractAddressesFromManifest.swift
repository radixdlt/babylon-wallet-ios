// MARK: - ExtractAddressesFromManifestRequest
public struct ExtractAddressesFromManifestRequest: Sendable, Codable, Hashable {
	public let networkId: NetworkID
	public let manifest: TransactionManifest

	public init(
		manifest: TransactionManifest,
		networkId: NetworkID
	) {
		self.manifest = manifest
		self.networkId = networkId
	}
}

extension ExtractAddressesFromManifestRequest {
	private enum CodingKeys: String, CodingKey {
		case networkId = "network_id"
		case manifest
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(manifest, forKey: .manifest)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let networkId: UInt8 = try decodeAndConvertToNumericType(container: container, key: .networkId)
		let manifest = try container.decode(TransactionManifest.self, forKey: .manifest)

		self.init(manifest: manifest, networkId: NetworkID(networkId))
	}
}

// MARK: - ExtractAddressesFromManifestResponse
public struct ExtractAddressesFromManifestResponse: Sendable, Codable, Hashable {
	// MARK: Stored properties

	public let packageAddresses: [PackageAddress]
	public let resourceAddresses: [ResourceAddress]
	public let componentAddresses: [ComponentAddress]
	public let accountAddresses: [AccountAddress_]

	public let accountsRequiringAuth: [AccountAddress_]
	public let accountsDepositedInto: [AccountAddress_]
	public let accountsWithdrawnFrom: [AccountAddress_]

	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case accountAddresses = "account_addresses"
		case packageAddresses = "package_addresses"
		case resourceAddresses = "resource_addresses"
		case componentAddresses = "component_addresses"

		case accountsDepositedInto = "accounts_deposited_into"
		case accountsRequiringAuth = "accounts_requiring_auth"
		case accountsWithdrawnFrom = "accounts_withdrawn_from"
	}
}
