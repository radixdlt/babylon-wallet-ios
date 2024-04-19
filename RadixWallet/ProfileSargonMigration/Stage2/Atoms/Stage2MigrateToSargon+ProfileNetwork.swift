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
//		accounts.hidden
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func accountsIncludingHidden() -> IdentifiedArrayOf<Account> {
//		accounts
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func hasSomeAccount() -> Bool {
//		!accounts.isEmpty
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	var numberOfAccountsIncludingHidden: Int {
//		accounts.count
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	#if DEBUG
	public mutating func deleteAccount(address: AccountAddress) {
//		accounts.remove(id: address)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
	#endif

	public mutating func updateAccount(_ account: Account) throws {
//		accounts[id: account.id] = account
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func addAccount(_ account: Account) throws {
//		guard accounts[id: account.id] == nil else {
//			throw AccountAlreadyExists()
//		}
//
//		accounts.append(account)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func hideAccounts(ids idsOfAccountsToHide: Set<Sargon.Account.ID>) {
//		var identifiedArrayOf = self.accounts
//		for id in idsOfAccountsToHide {
//			identifiedArrayOf[id: id]?.hide()
//
//			authorizedDapps.mutateAll { dapp in
//				dapp.referencesToAuthorizedPersonas.mutateAll { persona in
//					persona.sharedAccounts?.ids.remove(id)
//				}
//			}
//		}
//		self.accounts = identifiedArrayOf
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func getPersonas() -> IdentifiedArrayOf<Persona> {
//		personas.nonHidden
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func getHiddenPersonas() -> IdentifiedArrayOf<Persona> {
//		personas.hiden
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func personasIncludingHidden() -> IdentifiedArrayOf<Persona> {
//		personas
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public func hasSomePersona() -> Bool {
//		!personas.isEmpty
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func addPersona(_ persona: Persona) throws {
//		guard personas[id: persona.id] == nil else {
//			throw PersonaAlreadyExists()
//		}
//
//		personas.append(persona)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func updatePersona(_ persona: Persona) throws {
//		guard personas.updateOrAppend(persona) != nil else {
//			throw TryingToUpdateAPersonaWhichIsNotAlreadySaved()
//		}
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func hidePersonas(ids idsOfPersonaToHide: Set<Persona.ID>) {
//		for id in idsOfPersonaToHide {
//			/// Hide the personas themselves
//			personas[id: id]?.hide()
//
//			/// Remove the persona reference on any authorized dapp
//			authorizedDapps.mutateAll { dapp in
//				dapp.referencesToAuthorizedPersonas.remove(id: id)
//			}
//		}
//
//		/// Filter out dapps that do not reference any persona
//		authorizedDapps.filterInPlace(not(\.referencesToAuthorizedPersonas.isEmpty))
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func unhideAllEntities() {
//		accounts.mutateAll { $0.unhide() }
//		personas.mutateAll { $0.unhide() }
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var customDumpMirror: Mirror {
//		.init(
//			self,
//			children: [
//				"networkID": networkID,
//				"accounts": accounts,
//				"personas": personas,
//				"authorizedDapps": authorizedDapps,
//			],
//			displayStyle: .struct
//		)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var description: String {
//		"""
//		networkID: \(networkID),
//		accounts: \(accounts),
//		personas: \(personas),
//		authorizedDapps: \(authorizedDapps),
//		"""
		sargonProfileFinishMigrateAtEndOfStage1()
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
		//        guard dictionary.contains(where: { $0.key == network.networkID }) else {
		//            throw Error.unknownNetworkWithID(network.networkID)
		//        }
		//        let updatedElement = dictionary.updateValue(network, forKey: network.networkID)
		//        assert(updatedElement != nil)
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public mutating func add(_ network: ProfileNetwork) throws {
		//        guard !dictionary.contains(where: { $0.key == network.networkID }) else {
		//            throw Error.networkAlreadyExistsWithID(network.networkID)
		//        }
		//        let updatedElement = dictionary.updateValue(network, forKey: network.networkID)
		//        assert(updatedElement == nil)
		sargonProfileFinishMigrateAtEndOfStage1()
	}
}
