import ClientPrelude

// MARK: - SignersForAccountsGivenAddressesRequest
public struct SignersForAccountsGivenAddressesRequest: Sendable, Hashable {
	public let keychainAccessFactorSourcesAuthPrompt: String

	// Might be empty! And in case of empty...
	public let addresses: OrderedSet<AccountAddress>
	// ... we will use this NetworkID to get the first account and used that to sign
	public let networkID: NetworkID

	public init(
		networkID: NetworkID,
		addresses: OrderedSet<AccountAddress>,
		keychainAccessFactorSourcesAuthPrompt: String
	) {
		self.networkID = networkID
		self.addresses = addresses
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
	}
}
