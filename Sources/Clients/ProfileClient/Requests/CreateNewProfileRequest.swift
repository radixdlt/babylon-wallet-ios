import ClientPrelude
import Cryptography

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest: Sendable {
	public let networkAndGateway: AppPreferences.NetworkAndGateway
	public let curve25519FactorSourceMnemonic: Mnemonic
	public let nameOfFirstAccount: String?

	public init(
		networkAndGateway: AppPreferences.NetworkAndGateway,
		curve25519FactorSourceMnemonic: Mnemonic,
		nameOfFirstAccount: String?
	) {
		self.networkAndGateway = networkAndGateway
		self.curve25519FactorSourceMnemonic = curve25519FactorSourceMnemonic
		self.nameOfFirstAccount = nameOfFirstAccount
	}
}
