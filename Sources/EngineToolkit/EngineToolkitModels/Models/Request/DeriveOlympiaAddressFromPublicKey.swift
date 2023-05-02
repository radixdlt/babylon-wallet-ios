// MARK: - DeriveOlympiaAddressFromPublicKeyRequest
public struct DeriveOlympiaAddressFromPublicKeyRequest: Sendable, Codable, Hashable {
	public let network: OlympiaNetwork
	public let publicKey: Engine.PublicKey

	public init(
		network: OlympiaNetwork,
		publicKey: Engine.EcdsaSecp256k1PublicKey
	) {
		self.network = network
		self.publicKey = .ecdsaSecp256k1(publicKey)
	}
}

// MARK: - OlympiaNetwork
public enum OlympiaNetwork: String, Sendable, Codable, Hashable {
	case mainnet = "Mainnet"
	case stokenet = "Stokenet"
	case releasenet = "Releasenet"
	case rcnet = "Rcnet"
	case milestonenet = "Milestonenet"
	case devopsnet = "Devopsnet"
	case sandpitnet = "Sandpitnet"
	case localnet = "Localnet"
}

// MARK: - DeriveOlympiaAddressFromPublicKeyRequest.CodingKeys
extension DeriveOlympiaAddressFromPublicKeyRequest {
	private enum CodingKeys: String, CodingKey {
		case network
		case publicKey = "public_key"
	}
}

// MARK: - DeriveOlympiaAddressFromPublicKeyResponse
public struct DeriveOlympiaAddressFromPublicKeyResponse: Sendable, Codable, Hashable {
	public let olympiaAccountAddress: String

	public init(
		olympiaAccountAddress: String
	) {
		self.olympiaAccountAddress = olympiaAccountAddress
	}
}

// MARK: DeriveOlympiaAddressFromPublicKeyResponse.CodingKeys
extension DeriveOlympiaAddressFromPublicKeyResponse {
	private enum CodingKeys: String, CodingKey {
		case olympiaAccountAddress = "olympia_account_address"
	}
}
