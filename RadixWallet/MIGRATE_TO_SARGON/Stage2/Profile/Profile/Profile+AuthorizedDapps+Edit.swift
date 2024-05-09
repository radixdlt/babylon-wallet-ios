import Sargon

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
		_ persona: Persona
	) throws {
		let networkID = persona.networkID
		var network = try network(id: networkID)
		try network.updatePersona(persona)
		try updateOnNetwork(network)
	}

	/// Saves a `AuthorizedDapp` into the profile
	@discardableResult
	public mutating func addAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: AuthorizedDapp
	) throws -> AuthorizedDapp {
		let authorizedDapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = authorizedDapp.networkID
		var network = try network(id: networkID)
		guard !network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == authorizedDapp.dAppDefinitionAddress }) else {
			throw AuthorizedDappAlreadyExists()
		}
		var authorizedDapps = network.authorizedDapps.asIdentified()
		guard authorizedDapps.updateOrAppend(authorizedDapp) == nil else {
			fatalError("Incorrect implementation, should have been a new AuthorizedDapp")
		}
		network.authorizedDapps = authorizedDapps.elements
		try updateOnNetwork(network)
		return authorizedDapp
	}

	/// Forgets  a `AuthorizedDapp`
	public mutating func forgetAuthorizedDapp(
		_ authorizedDappID: AuthorizedDapp.ID,
		on networkID: NetworkID
	) throws {
		var network = try network(id: networkID)
		var authorizedDapps = network.authorizedDapps.asIdentified()
		guard authorizedDapps.remove(id: authorizedDappID) != nil else {
			throw DappWasNotConnected()
		}
		network.authorizedDapps = authorizedDapps.elements
		try updateOnNetwork(network)
	}

	@discardableResult
	private func validateAuthorizedPersonas(of authorizedDapp: AuthorizedDapp) throws -> AuthorizedDapp {
		let networkID = authorizedDapp.networkID
		let network = try network(id: networkID)

		// Validate that all Personas are known and that every Field.ID is known
		// for each Persona.
		struct AuthorizedDappReferencesUnknownPersonas: Swift.Error {}
		struct AuthorizedDappReferencesUnknownPersonaField: Swift.Error {}
		for personaNeedle in authorizedDapp.referencesToAuthorizedPersonas {
			guard let persona = network.getPersonas().first(where: { $0.address == personaNeedle.identityAddress }) else {
				throw AuthorizedDappReferencesUnknownPersonas()
			}

			let fieldIDNeedles: Set<PersonaDataEntryID> = personaNeedle.sharedPersonaData.entryIDs
			let fieldIDHaystack: Set<PersonaDataEntryID> = Set(persona.personaData.entries.map(\.id))
			guard fieldIDHaystack.isSuperset(of: fieldIDNeedles) else {
				throw AuthorizedDappReferencesUnknownPersonaField()
			}
		}

		// Validate that all Accounts are known
		let accountAddressNeedles: Set<AccountAddress> = Set(
			authorizedDapp.referencesToAuthorizedPersonas.flatMap {
				$0.sharedAccounts?.ids ?? []
			}
		)
		let accountAddressHaystack = Set(network.getAccounts().map(\.address))
		guard accountAddressHaystack.isSuperset(of: accountAddressNeedles) else {
			struct AuthorizedDappReferencesUnknownAccount: Swift.Error {}
			throw AuthorizedDappReferencesUnknownAccount()
		}
		// All good
		return authorizedDapp
	}

	/// Removes a Persona from a dApp in the Profile
	public mutating func deauthorizePersonaFromDapp(
		_ personaID: Persona.ID,
		dAppID: AuthorizedDapp.ID,
		networkID: NetworkID
	) throws {
		var network = try network(id: networkID)
		var authorizedDapps = network.authorizedDapps.asIdentified()
		guard var authorizedDapp = authorizedDapps[id: dAppID] else {
			throw AuthorizedDappDoesNotExists()
		}

		var referencesToAuthorizedPersonas = authorizedDapp.referencesToAuthorizedPersonas.asIdentified()
		guard referencesToAuthorizedPersonas.remove(id: personaID) != nil else {
			throw PersonaNotConnected()
		}
		authorizedDapp.referencesToAuthorizedPersonas = referencesToAuthorizedPersonas.elements

		guard authorizedDapps.updateOrAppend(authorizedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		network.authorizedDapps = authorizedDapps.elements
		try updateOnNetwork(network)
	}

	/// Updates a `AuthorizedDapp` in the profile
	public mutating func updateAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: AuthorizedDapp
	) throws {
		let authorizedDapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = authorizedDapp.networkID
		var network = try network(id: networkID)
		guard network.authorizedDapps.contains(where: { $0.dAppDefinitionAddress == authorizedDapp.dAppDefinitionAddress }) else {
			throw AuthorizedDappDoesNotExists()
		}
		var authorizedDapps = network.authorizedDapps.asIdentified()
		guard authorizedDapps.updateOrAppend(authorizedDapp) != nil else {
			fatalError("Incorrect implementation, should have been an existing AuthorizedDapp")
		}
		network.authorizedDapps = authorizedDapps.elements
		try updateOnNetwork(network)
	}

	/// Updates or adds a `AuthorizedDapp` in the profile
	public mutating func updateOrAddAuthorizedDapp(
		_ unvalidatedAuthorizedDapp: AuthorizedDapp
	) throws {
		let dapp = try validateAuthorizedPersonas(of: unvalidatedAuthorizedDapp)
		let networkID = dapp.networkID
		let network = try network(id: networkID)
		if network.authorizedDapps.contains(dapp) {
			try updateAuthorizedDapp(dapp)
		} else {
			try addAuthorizedDapp(dapp)
		}
	}
}

extension AuthorizedDapps {
	public func contains(dapp authorizedDapp: AuthorizedDapp) -> Bool {
		self[id: authorizedDapp.id] != nil
	}
}
