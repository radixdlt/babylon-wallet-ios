

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
		/// RETAddress that globally abnd uniquely identifies this Persona.
		public let identityAddress: IdentityAddress

		/// The display name of the Persona, as stored in `Profile.Network.Persona`
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
				let persona = self.getPersonas().first(where: { $0.address == simple.identityAddress })
			else {
				/// this is a sign that ProfileSnapshot is in a bad state somehow...
				throw DiscrepancyAuthorizedDappReferencedPersonaWhichDoesNotExist()
			}

			return try AuthorizedPersonaDetailed(
				identityAddress: persona.address,
				displayName: persona.displayName,
				// Need to disable, since broken in swiftformat 0.52.7
				// swiftformat:disable redundantClosure
				simpleAccounts: { if let sharedAccounts = simple.sharedAccounts {
					try .init(sharedAccounts.ids.map { accountAddress in
						guard
							let account = self.getAccounts().first(where: { $0.address == accountAddress })
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
					nil
				}}(),
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

					func pick<T>(
						from fullKeyPath: KeyPath<PersonaData, PersonaData.IdentifiedEntry<T>?>,
						using sharedKeyPath: KeyPath<Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData,
							PersonaDataEntryID?>
					) -> PersonaData.IdentifiedEntry<T>? {
						guard
							let identifiedEntry = full[keyPath: fullKeyPath]
						else {
							return nil
						}
						guard
							shared[keyPath: sharedKeyPath] == identifiedEntry.id
						else {
							return nil
						}
						return identifiedEntry
					}

					func filter<T>(
						from fullKeyPath: KeyPath<PersonaData, PersonaData.CollectionOfIdentifiedEntries<T>>,
						using sharedKeyPath: KeyPath<Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData, Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData.SharedCollection?>
					) throws -> PersonaData.CollectionOfIdentifiedEntries<T> {
						try .init(
							collection: .init(uncheckedUniqueElements: full[keyPath: fullKeyPath].filter { value in
								guard let sharedCollection = shared[keyPath: sharedKeyPath] else {
									return false
								}
								guard sharedCollection.ids.contains(value.id) else {
									return false
								}
								return true
							})
						)
					}

					let personaData = try PersonaData(
						name: pick(from: \.name, using: \.name),
						dateOfBirth: pick(from: \.dateOfBirth, using: \.dateOfBirth),
						companyName: pick(from: \.companyName, using: \.companyName),
						emailAddresses: filter(from: \.emailAddresses, using: \.emailAddresses),
						phoneNumbers: filter(from: \.phoneNumbers, using: \.phoneNumbers),
						urls: filter(from: \.urls, using: \.urls),
						postalAddresses: filter(from: \.postalAddresses, using: \.postalAddresses),
						creditCards: filter(from: \.creditCards, using: \.creditCards)
					)

					// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
					// we do not forget to handle it here.
					switch PersonaData.Entry.Kind.fullName {
					case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
					}

					return personaData
				}(),
				hasAuthenticationSigningKey: persona.hasAuthenticationSigningKey
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
