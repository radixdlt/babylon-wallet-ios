import Sargon

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: - TryingToUpdateAPersonaWhichIsNotAlreadySaved
struct TryingToUpdateAPersonaWhichIsNotAlreadySaved: Swift.Error {}

extension ProfileNetwork {
	public func getAccounts() -> Accounts {
		accounts.nonHidden
	}

	public func getHiddenAccounts() -> Accounts {
		accounts.hidden
	}

	public func accountsIncludingHidden() -> Accounts {
		accounts.asIdentified()
	}

	public func hasSomeAccount() -> Bool {
		!accounts.isEmpty
	}

	var numberOfAccountsIncludingHidden: Int {
		accounts.count
	}

	#if DEBUG
	public mutating func deleteAccount(address: AccountAddress) {
		var identified = accounts.asIdentified()
		identified.remove(id: address)
		accounts = identified.elements
	}
	#endif

	public mutating func updateAccount(_ account: Account) throws {
		var identified = accounts.asIdentified()
		identified[id: account.id] = account
		accounts = identified.elements
	}

	public mutating func addAccount(_ account: Account) throws {
		var identified = accounts.asIdentified()
		guard identified[id: account.id] == nil else {
			throw AccountAlreadyExists()
		}

		identified.append(account)

		accounts = identified.elements
	}

	public mutating func hideAccount(id: Account.ID) {
		var identified = accounts.asIdentified()
		identified[id: id]?.hide()
		authorizedDapps.mutateAll { dapp in
			dapp.referencesToAuthorizedPersonas.mutateAll { persona in
				persona.sharedAccounts?.ids.removeAll(where: { $0 == id })
			}
		}
		accounts = identified.elements
	}

	public mutating func unhideAccount(id: Account.ID) {
		var identifiedAccounts = accounts.asIdentified()
		identifiedAccounts[id: id]?.unhide()
		accounts = identifiedAccounts.elements
	}

	public func getPersonas() -> Personas {
		personas.asIdentified().nonHidden
	}

	public func getHiddenPersonas() -> Personas {
		personas.asIdentified().hidden
	}

	public func personasIncludingHidden() -> Personas {
		personas.asIdentified()
	}

	public func hasSomePersona() -> Bool {
		!personas.isEmpty
	}

	public mutating func addPersona(_ persona: Persona) throws {
		var identifiedPersonas = personas.asIdentified()
		guard identifiedPersonas[id: persona.id] == nil else {
			throw PersonaAlreadyExists()
		}

		identifiedPersonas.append(persona)
		self.personas = identifiedPersonas.elements
	}

	public mutating func updatePersona(_ persona: Persona) throws {
		var identifiedPersonas = personas.asIdentified()
		guard identifiedPersonas.updateOrAppend(persona) != nil else {
			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
		}
		self.personas = identifiedPersonas.elements
	}

	public mutating func hidePersona(id: Persona.ID) {
		var identifiedPersonas = personas.asIdentified()
		var identifiedAuthorizedDapps = authorizedDapps.asIdentified()

		/// Hide the personas themselves
		identifiedPersonas[id: id]?.hide()

		/// Remove the persona reference on any authorized dapp
		identifiedAuthorizedDapps.mutateAll { dapp in
			var referencesToAuthorizedPersonas = dapp.referencesToAuthorizedPersonas.asIdentified()
			referencesToAuthorizedPersonas.remove(id: id)
			dapp.referencesToAuthorizedPersonas = referencesToAuthorizedPersonas.elements
		}
		self.personas = identifiedPersonas.elements

		/// Filter out dapps that do not reference any persona
		identifiedAuthorizedDapps.filterInPlace(not(\.referencesToAuthorizedPersonas.isEmpty))
		self.authorizedDapps = identifiedAuthorizedDapps.elements
	}

	public mutating func unhidePersona(id: Persona.ID) {
		var identifiedPersonas = personas.asIdentified()
		identifiedPersonas[id: id]?.unhide()
		personas = identifiedPersonas.elements
	}

	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"networkID": self.id,
				"accounts": accounts,
				"personas": personas,
				"authorizedDapps": authorizedDapps,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		networkID: \(id),
		accounts: \(accounts),
		personas: \(personas),
		authorizedDapps: \(authorizedDapps),
		"""
	}
}

extension ProfileNetworks {
	var isEmpty: Bool {
		count == 0
	}

	public func network(id needle: NetworkID) throws -> ProfileNetwork {
		guard let network = self[id: needle] else {
			throw Error.unknownNetworkWithID(needle)
		}
		return network
	}

	public enum Error:
		Swift.Error,
		Sendable,
		Hashable
	{
		case unknownNetworkWithID(NetworkID)
		case networkAlreadyExistsWithID(NetworkID)
	}

	public mutating func update(_ network: ProfileNetwork) throws {
		guard self[id: network.id] != nil else {
			throw Error.unknownNetworkWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement != nil)
	}

	public mutating func add(_ network: ProfileNetwork) throws {
		guard self[id: network.id] == nil else {
			throw Error.networkAlreadyExistsWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement == nil)
	}
}
