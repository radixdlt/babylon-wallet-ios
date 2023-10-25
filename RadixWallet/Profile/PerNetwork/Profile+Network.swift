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

		public typealias Accounts = IdentifiedArrayOf<Account>

		/// An identifiable ordered set of `Account`s created by the user for this network,
		/// can be empty
		private var accounts: Accounts

		public typealias Personas = IdentifiedArrayOf<Persona>
		/// An identifiable ordered set of `Persona`s created by the user for this network.
		private var personas: Personas

		public typealias AuthorizedDapps = IdentifiedArrayOf<AuthorizedDapp>
		/// An identifiable ordered set of `AuthorizedDapp`s the user has connected to.
		private var authorizedDapps: AuthorizedDapps

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

	public func nextAccountIndex() -> Int {
		accounts.count
	}

	public mutating func updateAccount(_ account: Account) throws {
		try accounts.updateAccount(account)
	}

	public mutating func addAccount(
		_ account: Account
	) throws {
		guard accounts[id: account.id] == nil else {
			throw AccountAlreadyExists()
		}
		accounts.appendAccount(account)
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

	public func hasAnyPersona() -> Bool {
		!personas.isEmpty
	}

	public func nextPersonaIndex() -> Int {
		personas.count
	}

	public mutating func addPersona(
		_ persona: Persona
	) throws {
		guard personas[id: persona.id] == nil else {
			throw PersonaAlreadyExists()
		}

		let updatedElement = personas.updateOrAppend(persona)
		assert(updatedElement == nil, "We expected this to be a new, unique, Persona, thus we expected it to be have been inserted, but it was not. Maybe all properties except the IdentityAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")
	}

	public mutating func updatePersona(
		_ persona: Persona
	) throws {
		guard personas.updateOrAppend(persona) != nil else {
			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
		}
	}
}

// MARK: - AuthorizedDappAlreadyExists
struct AuthorizedDappAlreadyExists: Swift.Error {}

// MARK: - DappWasNotConnected
struct DappWasNotConnected: Swift.Error {}

extension Profile.Network {
	public func getAuthorizedDapps() -> AuthorizedDapps {
		let accountsOnNetwork = getAccounts()
		let personasOnNetwork = getPersonas()
		return authorizedDapps.compactMap { dapp in
			let personas = dapp.referencesToAuthorizedPersonas.filter { authorizedPersona in
				personasOnNetwork[id: authorizedPersona.id] != nil
			}

			guard !personas.isEmpty else {
				return nil
			}

			var dapp = dapp
			dapp.referencesToAuthorizedPersonas = personas

			for persona in personas {
				if let sharedAccounts = persona.sharedAccounts {
					let ids = sharedAccounts.ids.filter { address in
						accountsOnNetwork.contains {
							$0.address == address
						}
					}
					dapp.referencesToAuthorizedPersonas[id: persona.id]?.sharedAccounts?.ids = ids
				}
			}
			return dapp
		}.asIdentifiable()
	}

	public mutating func addAuthorizedDapp(
		_ authorizedDapp: AuthorizedDapp
	) throws {
		guard !authorizedDapps.contains(where: { $0.dAppDefinitionAddress == authorizedDapp.dAppDefinitionAddress }) else {
			throw AuthorizedDappAlreadyExists()
		}
		guard authorizedDapps.updateOrAppend(authorizedDapp) == nil else {
			fatalError("Incorrect implementation, should have been a new AuthorizedDapp")
		}
	}

	public mutating func forgetAuthorizedDapp(
		_ authorizedDappID: AuthorizedDapp.ID
	) throws {
		guard authorizedDapps.remove(id: authorizedDappID) != nil else {
			throw DappWasNotConnected()
		}
	}

	public mutating func updateAuthorizedDapp(
		_ authorizedDapp: AuthorizedDapp
	) throws {
		guard authorizedDapps[id: authorizedDapp.id] != nil else {
			throw AuthorizedDappDoesNotExists()
		}
		authorizedDapps.updateOrAppend(authorizedDapp)
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
