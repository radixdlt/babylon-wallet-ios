import Prelude

// MARK: ~~~=== LOGIC ===~~~
extension OnNetwork {
	public struct AccountForDisplay: Sendable, Hashable, Identifiable {
		public typealias ID = AccountAddress
		public var id: ID { address }
		public let address: AccountAddress
		public let label: NonEmpty<String>
		public let appearanceID: OnNetwork.Account.AppearanceID

		public init(
			address: AccountAddress,
			label: NonEmpty<String>,
			appearanceID: OnNetwork.Account.AppearanceID
		) {
			self.address = address
			self.label = label
			self.appearanceID = appearanceID
		}
	}

	public struct AuthorizedPersonaDetailed: Sendable, Hashable, Identifiable {
		public typealias ID = IdentityAddress
		public var id: ID { identityAddress }
		/// Address that globally abnd uniquely identifies this Persona.
		public let identityAddress: IdentityAddress

		// FIXME: change Persona and Account to require displayname, and make this non optional?
		/// The display name of the Persona, as stored in `OnNetwork.Persona`
		public let displayName: NonEmpty<String>

		/// The persona data that the user has given the Dapp access to,
		/// being the trippple: `(id, kind, value)`
		public let fields: IdentifiedArrayOf<OnNetwork.Persona.Field>

		/// Information of accounts the user has given the Dapp access to,
		/// being the tripple `(accountAddress, displayName, appearanceID)`
		public let simpleAccounts: OrderedSet<AccountForDisplay>?
	}

	public struct AuthorizedDappDetailed: Sendable, Hashable {
		public let networkID: Network.ID
		public let dAppDefinitionAddress: DappDefinitionAddress
		public let displayName: NonEmpty<String>
		public let detailedAuthorizedPersonas: IdentifiedArrayOf<OnNetwork.AuthorizedPersonaDetailed>
	}

	public func detailsForAuthorizedDapp(_ dapp: AuthorizedDapp) throws -> AuthorizedDappDetailed {
		guard
			dapp.networkID == self.networkID
		else {
			/// this is a sign that ProfileSnapshot is in a bad state somehow...
			throw NetworkDiscrepancyError()
		}
		let detailedAuthorizedPersonas = try IdentifiedArrayOf<OnNetwork.AuthorizedPersonaDetailed>(uniqueElements: dapp.referencesToAuthorizedPersonas.map { simple in

			guard
				let persona = self.personas.first(where: { $0.address == simple.identityAddress })
			else {
				/// this is a sign that ProfileSnapshot is in a bad state somehow...
				throw DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist()
			}

			return try AuthorizedPersonaDetailed(
				identityAddress: persona.address,
				displayName: persona.displayName,
				fields: .init(uniqueElements: simple.fieldIDs.map { fieldID in
					guard
						let field = persona.fields.first(where: { $0.id == fieldID })
					else {
						// FIXME: Should we maybe just skip this field instead of throwing an error? Probably?!
						throw AuthorizedDappReferencesFieldIDThatDoesNotExist()
					}
					return field
				}),
				simpleAccounts: {
					if let sharedAccounts = simple.sharedAccounts {
						return try .init(sharedAccounts.accountsReferencedByAddress.map { accountAddress in
							guard
								let account = self.accounts.first(where: { $0.address == accountAddress })
							else {
								throw AuthorizedDappReferencesAccountThatDoesNotExist()
							}
							return AccountForDisplay(
								address: account.address,
								label: account.displayName,
								appearanceID: account.appearanceID
							)
						})
					} else {
						return nil
					}
				}()
			)
		})

		return .init(
			networkID: networkID,
			dAppDefinitionAddress: dapp.dAppDefinitionAddress,
			displayName: dapp.displayName,
			detailedAuthorizedPersonas: detailedAuthorizedPersonas
		)
	}

	public struct NetworkDiscrepancyError: Swift.Error {}
	public struct DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist: Swift.Error {}
	public struct AuthorizedDappReferencesFieldIDThatDoesNotExist: Swift.Error {}
	public struct AuthorizedDappReferencesAccountThatDoesNotExist: Swift.Error {}
}
