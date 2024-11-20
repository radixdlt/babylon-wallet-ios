import Sargon

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: - TryingToUpdateAPersonaWhichIsNotAlreadySaved
struct TryingToUpdateAPersonaWhichIsNotAlreadySaved: Swift.Error {}

extension ProfileNetwork {
	func getAccounts() -> Accounts {
		accounts.nonDeleted.nonHidden
	}

	func getHiddenAccounts() -> Accounts {
		accounts.hidden
	}

	func accountsIncludingHidden() -> Accounts {
		accounts.asIdentified()
	}

	func hasSomeAccount() -> Bool {
		!accounts.isEmpty
	}

	var numberOfAccountsIncludingHidden: Int {
		accounts.count
	}

	func getAuthorizedDapps() -> AuthorizedDapps {
		authorizedDapps.asIdentified()
	}

	#if DEBUG
	mutating func deleteAccount(address: AccountAddress) {
		var identified = accounts.asIdentified()
		identified.remove(id: address)
		accounts = identified.elements
	}
	#endif

	mutating func updateAccount(_ account: Account) throws {
		var identified = accounts.asIdentified()
		identified[id: account.id] = account
		accounts = identified.elements
	}

	mutating func addAccount(_ account: Account) throws {
		var identified = accounts.asIdentified()
		guard identified[id: account.id] == nil else {
			throw AccountAlreadyExists()
		}

		identified.append(account)

		accounts = identified.elements
	}

	mutating func hideAccount(id: Account.ID) {
		var identified = accounts.asIdentified()
		identified[id: id]?.hide()
		authorizedDapps.mutateAll { dapp in
			dapp.referencesToAuthorizedPersonas.mutateAll { persona in
				persona.sharedAccounts?.ids.removeAll(where: { $0 == id })
			}
		}
		accounts = identified.elements
	}

	mutating func unhideAccount(id: Account.ID) {
		var identifiedAccounts = accounts.asIdentified()
		identifiedAccounts[id: id]?.unhide()
		accounts = identifiedAccounts.elements
	}

	func getPersonas() -> Personas {
		personas.asIdentified().nonHidden
	}

	func getHiddenPersonas() -> Personas {
		personas.asIdentified().hidden
	}

	func personasIncludingHidden() -> Personas {
		personas.asIdentified()
	}

	func hasSomePersona() -> Bool {
		!personas.isEmpty
	}

	mutating func addPersona(_ persona: Persona) throws {
		var identifiedPersonas = personas.asIdentified()
		guard identifiedPersonas[id: persona.id] == nil else {
			throw PersonaAlreadyExists()
		}

		identifiedPersonas.append(persona)
		self.personas = identifiedPersonas.elements
	}

	mutating func updatePersona(_ persona: Persona) throws {
		var identifiedPersonas = personas.asIdentified()
		guard identifiedPersonas.updateOrAppend(persona) != nil else {
			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
		}
		self.personas = identifiedPersonas.elements
	}

	mutating func hidePersona(id: Persona.ID) {
		var identifiedPersonas = personas.asIdentified()
		var identifiedAuthorizedDapps = authorizedDapps.asIdentified()

		/// Hide the persona themself
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

	mutating func unhidePersona(id: Persona.ID) {
		var identifiedPersonas = personas.asIdentified()
		identifiedPersonas[id: id]?.unhide()
		personas = identifiedPersonas.elements
	}

	func getHiddenResources() -> [ResourceIdentifier] {
		resourcePreferences.hiddenResources
	}

	var customDumpMirror: Mirror {
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

	var description: String {
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

	func network(id needle: NetworkID) throws -> ProfileNetwork {
		guard let network = self[id: needle] else {
			throw Error.unknownNetworkWithID(needle)
		}
		return network
	}

	enum Error:
		Swift.Error,
		Sendable,
		Hashable
	{
		case unknownNetworkWithID(NetworkID)
		case networkAlreadyExistsWithID(NetworkID)
	}

	mutating func update(_ network: ProfileNetwork) throws {
		guard self[id: network.id] != nil else {
			throw Error.unknownNetworkWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement != nil)
	}

	mutating func add(_ network: ProfileNetwork) throws {
		guard self[id: network.id] == nil else {
			throw Error.networkAlreadyExistsWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement == nil)
	}
}
