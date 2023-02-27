import Cryptography
import EngineToolkit
import Prelude

// MARK: - ConnectedDappDoesNotExists
struct ConnectedDappDoesNotExists: Swift.Error {}

// MARK: - DappWasNotConnected
struct DappWasNotConnected: Swift.Error {}

// MARK: - ConnectedDappAlreadyExists
struct ConnectedDappAlreadyExists: Swift.Error {}

// MARK: - PersonaNotConnected
struct PersonaNotConnected: Swift.Error {}

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

extension NonEmpty where Collection == IdentifiedArrayOf<OnNetwork.Account> {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	public mutating func appendAccount(_ account: OnNetwork.Account) -> OnNetwork.Account {
		var orderedSet = self.rawValue
		orderedSet.append(account)
		self = .init(rawValue: orderedSet)!
		return account
	}
}

extension Profile {
	public struct NetworkAlreadyExists: Swift.Error {}
	public struct AccountDoesNotHaveIndexZero: Swift.Error {}

	/// Throws if the network of the account is not new and does not have index 0.
	@discardableResult
	public mutating func add(
		account account0: OnNetwork.Account,
		toNewNetworkWithID networkID: NetworkID
	) throws -> OnNetwork {
		guard !containsNetwork(withID: networkID) else {
			throw NetworkAlreadyExists()
		}
		guard account0.index == 0 else {
			throw AccountDoesNotHaveIndexZero()
		}

		let onNetwork = OnNetwork(
			networkID: networkID,
			accounts: .init(rawValue: .init(uniqueElements: [account0]))!,
			personas: [],
			authorizedDapps: []
		)
		try self.perNetwork.add(onNetwork)
		return onNetwork
	}
}

// MARK: Add Virtual Account
extension Profile {
	/// Saves an `Account` into the profile
	public mutating func addAccount(
		_ account: OnNetwork.Account
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
			let onNetwork = OnNetwork(
				networkID: networkID,
				accounts: .init(rawValue: .init(uniqueElements: [account]))!,
				personas: [],
				authorizedDapps: []
			)
			try perNetwork.add(onNetwork)
		}
	}

	/// Saves a `AuthorizedDapp` into the profile
	@discardableResult
	public mutating func addConnectedDapp(
		_ unvalidatedConnectedDapp: OnNetwork.AuthorizedDapp
	) throws -> OnNetwork.AuthorizedDapp {
		let connectedDapp = try validateAuthorizedPersonas(of: unvalidatedConnectedDapp)
		let networkID = connectedDapp.networkID
		var network = try onNetwork(id: networkID)
		guard !network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == connectedDapp.dAppDefinitionAddress }) else {
			throw ConnectedDappAlreadyExists()
		}
		guard network.authorizedDapps.updateOrAppend(connectedDapp) == nil else {
			fatalError("Incorrect implementation, should have been a new AuthorizedDapp")
		}
		try updateOnNetwork(network)
		return connectedDapp
	}

	/// Forgets  a `AuthorizedDapp`
	public mutating func forgetConnectedDapp(
		_ connectedDappID: OnNetwork.AuthorizedDapp.ID,
		on networkID: NetworkID
	) async throws {
		var network = try onNetwork(id: networkID)
		guard network.authorizedDapps.remove(id: connectedDappID) != nil else {
			throw DappWasNotConnected()
		}

		try updateOnNetwork(network)
	}

	@discardableResult
	private func validateAuthorizedPersonas(of connectedDapp: OnNetwork.AuthorizedDapp) throws -> OnNetwork.AuthorizedDapp {
		let networkID = connectedDapp.networkID
		let network = try onNetwork(id: networkID)

		// Validate that all Personas are known and that every Field.ID is known
		// for each Persona.
		struct ConnectedDappReferencesUnknownPersonas: Swift.Error {}
		struct ConnectedDappReferencesUnknownPersonaField: Swift.Error {}
		for personaNeedle in connectedDapp.referencesToAuthorizedPersonas {
			guard let persona = network.personas.first(where: { $0.address == personaNeedle.identityAddress }) else {
				throw ConnectedDappReferencesUnknownPersonas()
			}
			let fieldIDNeedles = Set(personaNeedle.fieldIDs)
			let fieldIDHaystack = Set(persona.fields.map(\.id))
			guard fieldIDHaystack.isSuperset(of: fieldIDNeedles) else {
				throw ConnectedDappReferencesUnknownPersonaField()
			}
		}

		// Validate that all Accounts are known
		let accountAddressNeedles: Set<AccountAddress> = Set(
			connectedDapp.referencesToAuthorizedPersonas.flatMap {
				$0.sharedAccounts?.accountsReferencedByAddress ?? []
			}
		)
		let accountAddressHaystack = Set(network.accounts.map(\.address))
		guard accountAddressHaystack.isSuperset(of: accountAddressNeedles) else {
			struct ConnectedDappReferencesUnknownAccount: Swift.Error {}
			throw ConnectedDappReferencesUnknownAccount()
		}
		// All good
		return connectedDapp
	}

	/// Removes a Persona from a dApp in the Profile
	public mutating func disconnectPersonaFromDapp(
		_ personaID: OnNetwork.Persona.ID,
		dAppID: OnNetwork.AuthorizedDapp.ID,
		networkID: NetworkID
	) async throws {
		var network = try onNetwork(id: networkID)
		guard var connectedDapp = network.authorizedDapps[id: dAppID] else {
			throw ConnectedDappDoesNotExists()
		}

		guard connectedDapp.referencesToAuthorizedPersonas.remove(id: personaID) != nil else {
			throw PersonaNotConnected()
		}

		guard network.authorizedDapps.updateOrAppend(connectedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		try updateOnNetwork(network)
	}

	/// Updates a `AuthorizedDapp` in the profile
	public mutating func updateConnectedDapp(
		_ unvalidatedConnectedDapp: OnNetwork.AuthorizedDapp
	) throws {
		let connectedDapp = try validateAuthorizedPersonas(of: unvalidatedConnectedDapp)
		let networkID = connectedDapp.networkID
		var network = try onNetwork(id: networkID)
		guard network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == connectedDapp.dAppDefinitionAddress }) else {
			throw ConnectedDappDoesNotExists()
		}
		guard network.authorizedDapps.updateOrAppend(connectedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		try updateOnNetwork(network)
	}
}
