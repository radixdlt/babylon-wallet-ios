// MARK: - Profile.Network

extension Profile {
	// MARK: - Profile.Network
	/// **For a given network**: a list of accounts, personas and connected dApps.
	public struct Network:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// The ID of the network that has been used to generate the accounts, to which personas
		/// have been added and dApps connected.
		public let networkID: NetworkID

		public typealias Accounts = IdentifiedArrayOf<Account>

		/// An identifiable ordered set of `Account`s created by the user for this network.
		private var accounts: Accounts

		public typealias Personas = IdentifiedArrayOf<Persona>
		/// An identifiable ordered set of `Persona`s created by the user for this network.
		private var personas: Personas

		public typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
		/// An identifiable ordered set of `AuthorizedDapp`s the user has connected to.
		var authorizedDapps: AuthorizedDapps

		public init(
			networkID: NetworkID,
			accounts: Accounts,
			personas: Personas,
			authorizedDapps: AuthorizedDapps
		) {
			self.networkID = networkID
			self.accounts = accounts
			self.personas = personas
			self.authorizedDapps = authorizedDapps
		}
	}
}

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

extension Profile.Network {
	public func getAccounts() -> IdentifiedArrayOf<Account> {
		accounts.nonHidden
	}

	public func getHiddenAccounts() -> IdentifiedArrayOf<Account> {
		accounts.hidden
	}

	public func accountsIncludingHidden() -> IdentifiedArrayOf<Account> {
		accounts
	}

	public func hasSomeAccount() -> Bool {
		!accounts.isEmpty
	}

	var numberOfAccountsIncludingHidden: Int {
		accounts.count
	}

	#if DEBUG
	public mutating func deleteAccount(address: AccountAddress) {
		accounts.remove(id: address)
	}
	#endif

	public mutating func updateAccount(_ account: Account) throws {
		accounts[id: account.id] = account
	}

	public mutating func addAccount(_ account: Account) throws {
		guard accounts[id: account.id] == nil else {
			throw AccountAlreadyExists()
		}

		accounts.append(account)
	}

	public mutating func hideAccounts(ids idsOfAccountsToHide: Set<Profile.Network.Account.ID>) {
		var identifiedArrayOf = self.accounts
		for id in idsOfAccountsToHide {
			identifiedArrayOf[id: id]?.hide()

			authorizedDapps.mutateAll { dapp in
				dapp.referencesToAuthorizedPersonas.mutateAll { persona in
					persona.sharedAccounts?.ids.remove(id)
				}
			}
		}
		self.accounts = identifiedArrayOf
	}
}

// MARK: - PersonaAlreadyExists
struct PersonaAlreadyExists: Swift.Error {}

// MARK: - TryingToUpdateAPersonaWhichIsNotAlreadySaved
struct TryingToUpdateAPersonaWhichIsNotAlreadySaved: Swift.Error {}

extension Profile.Network {
	public func getPersonas() -> IdentifiedArrayOf<Persona> {
		personas.nonHidden
	}

	public func getHiddenPersonas() -> IdentifiedArrayOf<Persona> {
		personas.hiden
	}

	public func personasIncludingHidden() -> IdentifiedArrayOf<Persona> {
		personas
	}

	public func hasSomePersona() -> Bool {
		!personas.isEmpty
	}

	public mutating func addPersona(_ persona: Persona) throws {
		guard personas[id: persona.id] == nil else {
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
				dapp.referencesToAuthorizedPersonas.remove(id: id)
			}
		}

		/// Filter out dapps that do not reference any persona
		authorizedDapps.filterInPlace(not(\.referencesToAuthorizedPersonas.isEmpty))
	}
}

extension Profile.Network {
	public mutating func unhideAllEntities() {
		accounts.mutateAll { $0.unhide() }
		personas.mutateAll { $0.unhide() }
	}
}

extension Profile.Network {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"networkID": networkID,
				"accounts": accounts,
				"personas": personas,
				"authorizedDapps": authorizedDapps,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		networkID: \(networkID),
		accounts: \(accounts),
		personas: \(personas),
		authorizedDapps: \(authorizedDapps),
		"""
	}
}
