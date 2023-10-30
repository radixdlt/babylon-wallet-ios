import EngineToolkit

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

		public typealias Accounts = NonEmpty<IdentifiedArrayOf<Account>>

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

	public func hasAnyAccount() -> Bool {
		!accounts.isEmpty
	}

	public func nextAccountIndex() -> Int {
		accounts.count
	}

	public mutating func updateAccount(_ account: Account) throws {
		try accounts.updateAccount(account)
	}

	public mutating func addAccount(_ account: Account) throws {
		guard accounts[id: account.id] == nil else {
			throw AccountAlreadyExists()
		}
		accounts.appendAccount(account)
	}

	public mutating func hideAccount(_ account: Profile.Network.Account) {
		var identifiedArrayOf = accounts.rawValue
		identifiedArrayOf[id: account.address]?.hide()
		accounts = .init(rawValue: identifiedArrayOf)!

		authorizedDapps.mutateAll { dapp in
			dapp.referencesToAuthorizedPersonas.mutateAll { persona in
				persona.sharedAccounts?.ids.remove(account.address)
			}
		}
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

	public func hasAnyPersona() -> Bool {
		!personas.isEmpty
	}

	public func nextPersonaIndex() -> Int {
		personas.count
	}

	public mutating func addPersona(_ persona: Persona) throws {
		guard personas[id: persona.id] == nil else {
			throw PersonaAlreadyExists()
		}

		let updatedElement = personas.updateOrAppend(persona)
		assert(updatedElement == nil, "We expected this to be a new, unique, Persona, thus we expected it to be have been inserted, but it was not. Maybe all properties except the IdentityAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")
	}

	public mutating func updatePersona(_ persona: Persona) throws {
		guard personas.updateOrAppend(persona) != nil else {
			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
		}
	}

	public mutating func hidePersona(_ personaToHide: Persona) {
		/// Hide the persona itself
		personas[id: personaToHide.id]?.hide()

		/// Remove the persona reference on any authorized dapp
		authorizedDapps.mutateAll { dapp in
			dapp.referencesToAuthorizedPersonas.remove(id: personaToHide.id)
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
