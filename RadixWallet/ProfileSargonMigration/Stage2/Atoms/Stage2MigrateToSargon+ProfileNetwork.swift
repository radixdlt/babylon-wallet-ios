import Sargon

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: - TryingToUpdateAPersonaWhichIsNotAlreadySaved
struct TryingToUpdateAPersonaWhichIsNotAlreadySaved: Swift.Error {}

extension ProfileNetwork {
	public func getAccounts() -> IdentifiedArrayOf<Account> {
		accounts.nonHidden
	}

	public func getHiddenAccounts() -> IdentifiedArrayOf<Account> {
		accounts.hidden
	}

	public func accountsIncludingHidden() -> IdentifiedArrayOf<Account> {
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
		accounts.remove(address)
	}
	#endif

	public mutating func updateAccount(_ account: Account) throws {
		accounts[id: account.id] = account
	}

	public mutating func addAccount(_ account: Account) throws {
		guard accounts.get(id: account.id) == nil else {
			throw AccountAlreadyExists()
		}

		accounts.append(account)
	}

	public mutating func hideAccounts(ids idsOfAccountsToHide: Set<Sargon.Account.ID>) {
		var identifiedArrayOf = self.accounts
		for id in idsOfAccountsToHide {
			identifiedArrayOf[id: id]?.hide()

			authorizedDapps.mutateAll { dapp in
				dapp.referencesToAuthorizedPersonas.mutateAll { persona in
					persona.sharedAccounts?.ids.removeAll(where: { $0 == id })
				}
			}
		}
		self.accounts = identifiedArrayOf
	}

	public func getPersonas() -> IdentifiedArrayOf<Persona> {
		personas.nonHidden
	}

	public func getHiddenPersonas() -> IdentifiedArrayOf<Persona> {
		personas.hiden
	}

	public func personasIncludingHidden() -> IdentifiedArrayOf<Persona> {
		personas.asIdentified()
	}

	public func hasSomePersona() -> Bool {
		!personas.isEmpty
	}

	public mutating func addPersona(_ persona: Persona) throws {
		guard personas.get(id: persona.id) == nil else {
			throw PersonaAlreadyExists()
		}

		personas.append(persona)
	}

	public mutating func updatePersona(_ persona: Persona) throws {
		guard personas.updateOrAppend(persona) != nil else {
			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
		}
	}

	public mutating func hidePersonas(ids idsOfPersonaToHide: Set<Persona.ID>) {
		for id in idsOfPersonaToHide {
			/// Hide the personas themselves
			personas[id: id]?.hide()

			/// Remove the persona reference on any authorized dapp
			authorizedDapps.mutateAll { dapp in
				dapp.referencesToAuthorizedPersonas.remove(id)
			}
		}

		/// Filter out dapps that do not reference any persona
		authorizedDapps.filterInPlace(not(\.referencesToAuthorizedPersonas.isEmpty))
	}

	public mutating func unhideAllEntities() {
		accounts.mutateAll { $0.unhide() }
		personas.mutateAll { $0.unhide() }
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
		guard let network = self.get(id: needle) else {
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
		guard get(id: network.id) != nil else {
			throw Error.unknownNetworkWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement != nil)
	}

	public mutating func add(_ network: ProfileNetwork) throws {
		guard get(id: network.id) == nil else {
			throw Error.networkAlreadyExistsWithID(network.id)
		}
		let updatedElement = self.updateOrAppend(network)
		assert(updatedElement == nil)
	}
}
