import Cryptography
import EngineToolkit
import Prelude

// MARK: - AuthorizedDappDoesNotExists
public struct AuthorizedDappDoesNotExists: Swift.Error {
	public init() {}
}

// MARK: - DappWasNotConnected
struct DappWasNotConnected: Swift.Error {}

// MARK: - AuthorizedDappAlreadyExists
struct AuthorizedDappAlreadyExists: Swift.Error {}

extension Profile {
	/// Updates a `Persona` in the profile
	public mutating func updatePersona(
		_ persona: Profile.Network.Persona
	) throws {
		let networkID = persona.networkID
		var network = try network(id: networkID)
		guard network.personas.updateOrAppend(persona) != nil else {
			fatalError("Incorrect implementation, should have been an existing Persona")
		}
		try updateOnNetwork(network)
	}

	/// Saves a `AuthorizedDapp` into the profile
	@discardableResult
	public mutating func addAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: Profile.Network.AuthorizedDapp
	) throws -> Profile.Network.AuthorizedDapp {
		let authorizedDapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = authorizedDapp.networkID
		var network = try network(id: networkID)
		guard !network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == authorizedDapp.dAppDefinitionAddress }) else {
			throw AuthorizedDappAlreadyExists()
		}
		guard network.authorizedDapps.updateOrAppend(authorizedDapp) == nil else {
			fatalError("Incorrect implementation, should have been a new AuthorizedDapp")
		}
		try updateOnNetwork(network)
		return authorizedDapp
	}

	/// Forgets  a `AuthorizedDapp`
	public mutating func forgetAuthorizedDapp(
		_ authorizedDappID: Profile.Network.AuthorizedDapp.ID,
		on networkID: NetworkID
	) throws {
		var network = try network(id: networkID)
		guard network.authorizedDapps.remove(id: authorizedDappID) != nil else {
			throw DappWasNotConnected()
		}

		try updateOnNetwork(network)
	}

	@discardableResult
	private func validateAuthorizedPersonas(of authorizedDapp: Profile.Network.AuthorizedDapp) throws -> Profile.Network.AuthorizedDapp {
		let networkID = authorizedDapp.networkID
		let network = try network(id: networkID)

		// Validate that all Personas are known and that every Field.ID is known
		// for each Persona.
		struct AuthorizedDappReferencesUnknownPersonas: Swift.Error {}
		struct AuthorizedDappReferencesUnknownPersonaField: Swift.Error {}
		for personaNeedle in authorizedDapp.referencesToAuthorizedPersonas {
			guard let persona = network.personas.first(where: { $0.address == personaNeedle.identityAddress }) else {
				throw AuthorizedDappReferencesUnknownPersonas()
			}
			let fieldIDNeedles = personaNeedle.sharedFieldIDs ?? []
			let fieldIDHaystack = Set(persona.fields.map(\.id))
			guard fieldIDHaystack.isSuperset(of: fieldIDNeedles) else {
				throw AuthorizedDappReferencesUnknownPersonaField()
			}
		}

		// Validate that all Accounts are known
		let accountAddressNeedles: Set<AccountAddress> = Set(
			authorizedDapp.referencesToAuthorizedPersonas.flatMap {
				$0.sharedAccounts?.accountsReferencedByAddress ?? []
			}
		)
		let accountAddressHaystack = Set(network.accounts.map(\.address))
		guard accountAddressHaystack.isSuperset(of: accountAddressNeedles) else {
			struct AuthorizedDappReferencesUnknownAccount: Swift.Error {}
			throw AuthorizedDappReferencesUnknownAccount()
		}
		// All good
		return authorizedDapp
	}

	/// Removes a Persona from a dApp in the Profile
	public mutating func deauthorizePersonaFromDapp(
		_ personaID: Profile.Network.Persona.ID,
		dAppID: Profile.Network.AuthorizedDapp.ID,
		networkID: NetworkID
	) throws {
		var network = try network(id: networkID)
		guard var authorizedDapp = network.authorizedDapps[id: dAppID] else {
			throw AuthorizedDappDoesNotExists()
		}

		guard authorizedDapp.referencesToAuthorizedPersonas.remove(id: personaID) != nil else {
			throw PersonaNotConnected()
		}

		guard network.authorizedDapps.updateOrAppend(authorizedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		try updateOnNetwork(network)
	}

	/// Updates a `AuthorizedDapp` in the profile
	public mutating func updateAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: Profile.Network.AuthorizedDapp
	) throws {
		let authorizedDapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = authorizedDapp.networkID
		var network = try network(id: networkID)
		guard network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == authorizedDapp.dAppDefinitionAddress }) else {
			throw AuthorizedDappDoesNotExists()
		}
		guard network.authorizedDapps.updateOrAppend(authorizedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		try updateOnNetwork(network)
	}

	/// Updates or adds a `AuthorizedDapp` in the profile
	public mutating func updateOrAddAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: Profile.Network.AuthorizedDapp
	) throws {
		let dapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = dapp.networkID
		var network = try network(id: networkID)
		if network.authorizedDapps.contains(dapp: dapp) {
			try updateAuthorizedDapp(dapp)
		} else {
			try addAuthorizedDapp(dapp)
		}
	}
}

extension Profile.Network.AuthorizedDapps {
	public func contains(dapp authorizedDapp: Profile.Network.AuthorizedDapp) -> Bool {
		self[id: authorizedDapp.id] != nil
	}
}
