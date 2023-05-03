import Cryptography
import EngineToolkit
import Prelude

// MARK: - PersonaNotConnected
struct PersonaNotConnected: Swift.Error {}

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

extension Profile.Network.Accounts {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	public mutating func appendAccount(_ account: Profile.Network.Account) -> Profile.Network.Account {
		var identifiedArrayOf = self.rawValue
		let (wasInserted, _) = identifiedArrayOf.append(account)
		assert(wasInserted, "We expected this to be a new, unique, Account, thus we expected it to be have been inserted, but it was not. Maybe all properties except the AccountAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")
		self = .init(rawValue: identifiedArrayOf)!
		return account
	}
}

// MARK: Add Virtual Account
extension Profile {
	/// Saves an `Account` into the profile
	public mutating func addAccount(
		_ account: Profile.Network.Account,
		shouldUpdateFactorSourceNextDerivationIndex: Bool = true
	) throws {
		let networkID = account.networkID
		// can be nil if this is a new network
		let maybeNetwork = try? network(id: networkID)

		if var network = maybeNetwork {
			guard !network.accounts.contains(where: { $0 == account }) else {
				throw AccountAlreadyExists()
			}
			network.accounts.appendAccount(account)
			try updateOnNetwork(network)
		} else {
			let network = Profile.Network(
				networkID: networkID,
				accounts: .init(rawValue: .init(uniqueElements: [account]))!,
				personas: [],
				authorizedDapps: []
			)
			try networks.add(network)
		}

		guard shouldUpdateFactorSourceNextDerivationIndex else {
			return
		}
		switch account.securityState {
		case let .unsecured(entityControl):
			let factorSourceID = entityControl.genesisFactorInstance.factorSourceID
			try self.factorSources.updateFactorSource(id: factorSourceID) {
				try $0.increaseNextDerivationIndex(for: account.kind, networkID: account.networkID)
			}
		}
	}
}
