

// MARK: ~~~=== LOGIC ===~~~
extension ProfileNetwork {
	public struct AccountForDisplay: Sendable, Hashable, Identifiable {
		public typealias ID = AccountAddress
		public var id: ID { address }
		public let address: AccountAddress
		public let label: NonEmpty<String>
		public let appearanceID: AppearanceID

		public init(
			address: AccountAddress,
			label: NonEmpty<String>,
			appearanceID: AppearanceID
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

		/// The display name of the Persona, as stored in `Persona`
		public let displayName: NonEmptyString

		/// Information of accounts the user has given the Dapp access to,
		/// being the tripple `(accountAddress, displayName, appearanceID)`
		public let simpleAccounts: OrderedSet<AccountForDisplay>?

		/// The persona data that the user has given the Dapp access to
		public let sharedPersonaData: PersonaData

		/// If this persona has an auth sign key created
		public let hasAuthenticationSigningKey: Bool
	}

	public struct AuthorizedDappDetailed: Sendable, Hashable {
		public let networkID: NetworkID
		public let dAppDefinitionAddress: AccountAddress
		public let displayName: NonEmptyString?
		public let detailedAuthorizedPersonas: IdentifiedArrayOf<ProfileNetwork.AuthorizedPersonaDetailed>
	}

	public func detailsForAuthorizedDapp(_ dapp: AuthorizedDapp) throws -> AuthorizedDappDetailed {
		guard
			dapp.networkID == self.id
		else {
			/// this is a sign that Profile is in a bad state somehow...
			throw NetworkDiscrepancyError()
		}
		let detailedAuthorizedPersonas = try IdentifiedArrayOf<ProfileNetwork.AuthorizedPersonaDetailed>(uniqueElements: dapp.referencesToAuthorizedPersonas.map {
			simple in

			guard
				let persona = self.getPersonas().first(where: { $0.address == simple.identityAddress })
			else {
				/// this is a sign that Profile is in a bad state somehow...
				throw DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist()
			}
			let displayName = persona.displayName.asNonEmpty
			return try AuthorizedPersonaDetailed(
				identityAddress: persona.address,
				displayName: displayName,
				// Need to disable, since broken in swiftformat 0.52.7
				// swiftformat:disable redundantClosure
				simpleAccounts: {
					if let sharedAccounts = simple.sharedAccounts {
						try .init(sharedAccounts.ids.map { accountAddress in
							guard
								let account = self.getAccounts().first(where: { $0.address == accountAddress })
							else {
								throw AuthorizedDappReferencesAccountThatDoesNotExist()
							}
							return AccountForDisplay(
								address: account.address,
								label: account.displayName.asNonEmpty,
								appearanceID: account.appearanceID
							)
						})
					} else {
						nil
					}
				}(),
				// swiftformat:enable redundantClosure
				sharedPersonaData: {
					let full = persona.personaData
					let fullIDs = Set(full.entries.map(\.id))
					let shared = simple.sharedPersonaData
					let sharedIDs = shared.entryIDs

					guard
						fullIDs.isSuperset(of: sharedIDs)
					else {
						loggerGlobal.error("Profile discrepancy - most likely caused by incorrect implementation of DappInteractionFlow and updating of shared persona data. \n\nDetails [persona.personaData.ids] \(fullIDs) != \(sharedIDs) [simple.sharedPersonaData]\n\npersona.personaData: \(persona.personaData)\n\nsimple.sharedPersonaData:\(shared)")
						throw AuthorizedDappReferencesFieldIDThatDoesNotExist()
					}

					return PersonaData(
						name: { () -> PersonaDataIdentifiedName? in
							guard
								let identifiedEntry = full.name
							else {
								return nil
							}
							guard
								let idOfSharedName = shared.name,
								idOfSharedName == identifiedEntry.id
							else {
								return nil
							}
							return PersonaDataIdentifiedName(id: idOfSharedName, value: identifiedEntry.value)
						}(),
						phoneNumbers: .init(collection: full.phoneNumbers.collection.filter(
							{ (x: PersonaDataIdentifiedPhoneNumber) -> Bool in
								shared.phoneNumbers?.ids.contains(where: { $0 == x.id }) ?? false
							}
						)),
						emailAddresses: .init(collection: full.emailAddresses.collection.filter(
							{ (x: PersonaDataIdentifiedEmailAddress) -> Bool in
								shared.emailAddresses?.ids.contains(where: { $0 == x.id }) ?? false
							}
						))
					)
				}(),
				hasAuthenticationSigningKey: persona.hasAuthenticationSigningKey
			)
		})

		return .init(
			networkID: id,
			dAppDefinitionAddress: dapp.dAppDefinitionAddress,
			displayName: dapp.displayName.map { NonEmptyString(rawValue: $0) } ?? nil,
			detailedAuthorizedPersonas: detailedAuthorizedPersonas
		)
	}

	public struct NetworkDiscrepancyError: Swift.Error {}
	public struct DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist: Swift.Error {}
	public struct AuthorizedDappReferencesFieldIDThatDoesNotExist: Swift.Error {}
	public struct AuthorizedDappReferencesAccountThatDoesNotExist: Swift.Error {}
}
