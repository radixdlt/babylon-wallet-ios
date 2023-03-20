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
		var orderedSet = self.rawValue
		orderedSet.append(account)
		self = .init(rawValue: orderedSet)!
		return account
	}
}

// MARK: Add Virtual Account
extension Profile {
	/// Saves an `Account` into the profile
	public mutating func addAccount(
		_ account: Profile.Network.Account
	) throws {
		let networkID = account.networkID
		// can be nil if this is a new network
		let maybeNetwork = try? onNetwork(id: networkID)

		if var onNetwork = maybeNetwork {
			guard !onNetwork.accounts.contains(where: { $0 == account }) else {
				throw AccountAlreadyExists()
			}
			onNetwork.accounts.appendAccount(account)
			try updateOnNetwork(onNetwork)
		} else {
			let onNetwork = Profile.Network(
				networkID: networkID,
				accounts: .init(rawValue: .init(uniqueElements: [account]))!,
				personas: [],
				authorizedDapps: []
			)
			try networks.add(onNetwork)
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
