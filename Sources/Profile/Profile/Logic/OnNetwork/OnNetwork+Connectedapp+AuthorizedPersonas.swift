import Prelude

// MARK: ~~~=== LOGIC ===~~~
public extension OnNetwork {
	struct AccountForDisplay: Sendable, Hashable {
		public let address: AccountAddress
		public let label: String?
		public let appearanceID: OnNetwork.Account.AppearanceID

		public init(
			address: AccountAddress,
			label: String?,
			appearanceID: OnNetwork.Account.AppearanceID
		) {
			self.address = address
			self.label = label
			self.appearanceID = appearanceID
		}
	}

	struct AuthorizedPersona: Sendable, Hashable {
		/// Address that globally abnd uniquely identifies this Persona.
		public let identityAddress: IdentityAddress

		// FIXME: change Persona and Account to require displayname, and make this non optional?
		/// The display name of the Persona, as stored in `OnNetwork.Persona`
		public let displayName: String?

		/// The persona data that the user has given the Dapp access to,
		/// being the trippple: `(id, kind, value)`
		public let fields: OrderedSet<OnNetwork.Persona.Field>

		/// Information of accounts the user has given the Dapp access to,
		/// being the tripple `(accountAddress, displayName, appearanceID)`
		public let simpleAccounts: OrderedSet<AccountForDisplay>
	}

	func authorizedPersonas(dapp: ConnectedDapp) throws -> OrderedSet<AuthorizedPersona> {
		guard
			dapp.networkID == self.networkID
		else {
			/// this is a sign that ProfileSnapshot is in a bad state somehow...
			throw NetworkDiscrepancyError()
		}

		return try .init(dapp.referencesToAuthorizedPersonas.map { simple in

			guard
				let persona = self.personas.first(where: { $0.address == simple.identityAddress })
			else {
				/// this is a sign that ProfileSnapshot is in a bad state somehow...
				throw DiscrepancyConnectedDappReferencedPersonaWhichDoesNotExist()
			}

			return AuthorizedPersona(
				identityAddress: persona.address,
				displayName: persona.displayName,
				fields: try .init(simple.fieldIDs.map { fieldID in
					guard
						let field = persona.fields.first(where: { $0.id == fieldID })
					else {
						// FIXME: Should we maybe just skip this field instead of throwing an error? Probably?!
						throw ConnectedDappReferencesFieldIDThatDoesNotExist()
					}
					return field
				}),
				simpleAccounts: try .init(simple.sharedAccounts.accountsReferencedByAddress.map { accountAddress in
					guard
						let account = self.accounts.first(where: { $0.address == accountAddress })
					else {
						throw ConnectedDappReferencesAccountThatDoesNotExist()
					}
					return AccountForDisplay(
						address: account.address,
						label: account.displayName,
						appearanceID: account.appearanceID
					)
				})
			)
		})
	}

	struct NetworkDiscrepancyError: Swift.Error {}
	struct DiscrepancyConnectedDappReferencedPersonaWhichDoesNotExist: Swift.Error {}
	struct ConnectedDappReferencesFieldIDThatDoesNotExist: Swift.Error {}
	struct ConnectedDappReferencesAccountThatDoesNotExist: Swift.Error {}
}
