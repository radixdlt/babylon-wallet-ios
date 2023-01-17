import ClientPrelude

// MARK: - CreateAccountRequest
public struct CreateAccountRequest: Sendable, Hashable {
	public let overridingNetworkID: NetworkID?
	public let keychainAccessFactorSourcesAuthPrompt: String
	public let accountName: String?

	public init(
		overridingNetworkID: NetworkID?,
		keychainAccessFactorSourcesAuthPrompt: String,
		accountName: String?
	) {
		self.overridingNetworkID = overridingNetworkID
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
		self.accountName = accountName
	}
}
