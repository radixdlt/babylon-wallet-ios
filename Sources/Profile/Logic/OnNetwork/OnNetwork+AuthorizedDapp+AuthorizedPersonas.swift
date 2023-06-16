import EngineToolkit
import Prelude

// MARK: ~~~=== LOGIC ===~~~
extension Profile.Network {
	public struct AccountForDisplay: Sendable, Hashable, Identifiable {
		public typealias ID = AccountAddress
		public var id: ID { address }
		public let address: AccountAddress
		public let label: NonEmpty<String>
		public let appearanceID: Profile.Network.Account.AppearanceID

		public init(
			address: AccountAddress,
			label: NonEmpty<String>,
			appearanceID: Profile.Network.Account.AppearanceID
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

		/// The display name of the Persona, as stored in `Profile.Network.Persona`
		public let displayName: NonEmptyString

		/// Information of accounts the user has given the Dapp access to,
		/// being the tripple `(accountAddress, displayName, appearanceID)`
		public let simpleAccounts: OrderedSet<AccountForDisplay>?

		/// The persona data that the user has given the Dapp access to,
		/// being the trippple: `(id, kind, value)`
		public let sharedFields: IdentifiedArrayOf<Profile.Network.Persona.Field>?

		/// If this persona has an auth sign key created
		public let hasAuthenticationSigningKey: Bool
	}

	public struct AuthorizedDappDetailed: Sendable, Hashable {
		public let networkID: Radix.Network.ID
		public let dAppDefinitionAddress: AccountAddress
		public let displayName: NonEmptyString?
		public let detailedAuthorizedPersonas: IdentifiedArrayOf<Profile.Network.AuthorizedPersonaDetailed>
	}

	public func detailsForAuthorizedDapp(_ dapp: AuthorizedDapp) throws -> AuthorizedDappDetailed {
		guard
			dapp.networkID == self.networkID
		else {
			/// this is a sign that ProfileSnapshot is in a bad state somehow...
			throw NetworkDiscrepancyError()
		}
		let detailedAuthorizedPersonas = try IdentifiedArrayOf<Profile.Network.AuthorizedPersonaDetailed>(uniqueElements: dapp.referencesToAuthorizedPersonas.map { simple in

			guard
				let persona = self.personas.first(where: { $0.address == simple.identityAddress })
			else {
				/// this is a sign that ProfileSnapshot is in a bad state somehow...
				throw DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist()
			}

			return try AuthorizedPersonaDetailed(
				identityAddress: persona.address,
				displayName: persona.displayName,
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
				}(),
				sharedFields: {
					guard let sharedFieldIDs = simple.sharedFieldIDs else { return nil }
					let presentFields = sharedFieldIDs.compactMap { fieldID in
						persona.fields.first { $0.id == fieldID }
					}
					return .init(uniqueElements: presentFields)
				}(), hasAuthenticationSigningKey: persona.hasAuthenticationSigningKey
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
