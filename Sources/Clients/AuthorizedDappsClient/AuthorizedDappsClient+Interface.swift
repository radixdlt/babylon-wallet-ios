import ClientPrelude
import EngineKit
import Profile

// MARK: - AuthorizedDappsClient
public struct AuthorizedDappsClient: Sendable {
	public var getAuthorizedDapps: GetAuthorizedDapps
	public var addAuthorizedDapp: AddAuthorizedDapp
	public var forgetAuthorizedDapp: ForgetAuthorizedDapp
	public var updateAuthorizedDapp: UpdateAuthorizedDapp
	public var updateOrAddAuthorizedDapp: UpdateOrAddAuthorizedDapp
	public var deauthorizePersonaFromDapp: DeauthorizePersonaFromDapp
	public var detailsForAuthorizedDapp: DetailsForAuthorizedDapp

	public init(
		getAuthorizedDapps: @escaping GetAuthorizedDapps,
		addAuthorizedDapp: @escaping AddAuthorizedDapp,
		forgetAuthorizedDapp: @escaping ForgetAuthorizedDapp,
		updateAuthorizedDapp: @escaping UpdateAuthorizedDapp,
		updateOrAddAuthorizedDapp: @escaping UpdateOrAddAuthorizedDapp,
		deauthorizePersonaFromDapp: @escaping DeauthorizePersonaFromDapp,
		detailsForAuthorizedDapp: @escaping DetailsForAuthorizedDapp
	) {
		self.getAuthorizedDapps = getAuthorizedDapps
		self.addAuthorizedDapp = addAuthorizedDapp
		self.forgetAuthorizedDapp = forgetAuthorizedDapp
		self.updateAuthorizedDapp = updateAuthorizedDapp
		self.updateOrAddAuthorizedDapp = updateOrAddAuthorizedDapp
		self.deauthorizePersonaFromDapp = deauthorizePersonaFromDapp
		self.detailsForAuthorizedDapp = detailsForAuthorizedDapp
	}
}

extension AuthorizedDappsClient {
	public typealias GetAuthorizedDapps = @Sendable () async throws -> Profile.Network.AuthorizedDapps
	public typealias DetailsForAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Profile.Network.AuthorizedDappDetailed
	public typealias AddAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias UpdateOrAddAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias ForgetAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp.ID, NetworkID?) async throws -> Void
	public typealias UpdateAuthorizedDapp = @Sendable (Profile.Network.AuthorizedDapp) async throws -> Void
	public typealias DeauthorizePersonaFromDapp = @Sendable (Profile.Network.Persona.ID, Profile.Network.AuthorizedDapp.ID, NetworkID) async throws -> Void
}

extension AuthorizedDappsClient {
	public func getDetailedDapp(
		_ id: Profile.Network.AuthorizedDapp.ID
	) async throws -> Profile.Network.AuthorizedDappDetailed {
		let dApps = try await getAuthorizedDapps()
		guard let dApp = dApps[id: id] else {
			throw AuthorizedDappDoesNotExists()
		}
		return try await detailsForAuthorizedDapp(dApp)
	}

	public func getDappsAuthorizedByPersona(
		_ id: Profile.Network.Persona.ID
	) async throws -> IdentifiedArrayOf<Profile.Network.AuthorizedDapp> {
		try await getAuthorizedDapps().filter { $0.referencesToAuthorizedPersonas.ids.contains(id) }
	}

	public func removeBrokenReferencesToSharedPersonaData(
		personaCurrent: Profile.Network.Persona,
		personaUpdated: Profile.Network.Persona
	) async throws {
		guard personaCurrent.id == personaUpdated.id else {
			struct PersonaIDMismatch: Swift.Error {}
			throw PersonaIDMismatch()
		}
		let identityAddress = personaCurrent.address
		let dApps = try await getAuthorizedDapps()

		// We only care about the updated persona
		let idsOfEntriesToKeep = Set(personaUpdated.personaData.entries.map(\.id))

		for authorizedDapp in dApps {
			var updatedAuthedDapp = authorizedDapp
			for personaSimple in authorizedDapp.referencesToAuthorizedPersonas {
				guard personaSimple.identityAddress == identityAddress else {
					// irrelvant Persona
					continue
				}
				// Relevant Persona => check if there are any old PersonaData entries that needs deleting
				let idsOfEntriesToDelete = personaSimple.sharedPersonaData.entryIDs.subtracting(idsOfEntriesToKeep)

				guard !idsOfEntriesToDelete.isEmpty else {
					// No old entries needs to be deleted.
					continue
				}

				loggerGlobal.notice("Pruning stale PersonaData entries with IDs: \(idsOfEntriesToDelete), for persona: \(personaUpdated.address) (\(personaUpdated.displayName.rawValue)), for Dapp: \(authorizedDapp)")
				var authorizedPersonaSimple = personaSimple

				authorizedPersonaSimple.sharedPersonaData.remove(ids: idsOfEntriesToDelete)

				// Write back to `updatedAuthedDapp`
				updatedAuthedDapp.referencesToAuthorizedPersonas[id: authorizedPersonaSimple.id] = authorizedPersonaSimple

				// Soundness check
				if
					!Set(personaUpdated.personaData.entries.map(\.id))
					.isSuperset(
						of:
						updatedAuthedDapp
							.referencesToAuthorizedPersonas[id: authorizedPersonaSimple.id]!
							.sharedPersonaData
							.entryIDs
					)
				{
					let errMsg = "Incorrect implementation, failed to prune stale PersonaData entries for authorizedDapp"
					assertionFailure(errMsg)
					loggerGlobal.error(.init(stringLiteral: errMsg))
				}
			}
			if updatedAuthedDapp != authorizedDapp {
				// Write back `updatedAuthedDapp` to Profile only if changes were needed
				try await updateAuthorizedDapp(updatedAuthedDapp)
			} else {
				loggerGlobal.feature("nothing to do... skipped updating authorizedDapp")
			}
		}
	}
}

extension Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData {
	private mutating func remove(id: PersonaDataEntryID) {
		func removeCollectionIfNeeded(
			at keyPath: WritableKeyPath<Self, Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedPersonaData.SharedCollection?>
		) {
			guard
				var collection = self[keyPath: keyPath],
				collection.ids.contains(id)
			else { return }
			collection.ids.remove(id)
			switch collection.request.quantifier {
			case .atLeast:
				if collection.ids.count < collection.request.quantity {
					// must delete whole collection since requested quantity is no longer fulfilled.
					self[keyPath: keyPath] = nil
				}
			case .exactly:
				// Must delete whole collection since requested quantity is no longer fulfilled,
				// since we **just** deleted the id from `ids`.
				self[keyPath: keyPath] = nil
			}
		}

		func removeEntryIfNeeded(
			at keyPath: WritableKeyPath<Self, PersonaDataEntryID?>
		) {
			guard self[keyPath: keyPath] == id else { return }
			self[keyPath: keyPath] = nil
		}

		removeEntryIfNeeded(at: \.name)
		removeEntryIfNeeded(at: \.dateOfBirth)
		removeEntryIfNeeded(at: \.companyName)
		removeCollectionIfNeeded(at: \.emailAddresses)
		removeCollectionIfNeeded(at: \.phoneNumbers)
		removeCollectionIfNeeded(at: \.urls)
		removeCollectionIfNeeded(at: \.postalAddresses)
		removeCollectionIfNeeded(at: \.creditCards)

		// The only purpose of this switch is to make sure we get a compilation error when we add a new PersonaData.Entry kind, so
		// we do not forget to handle it here.
		switch PersonaData.Entry.Kind.fullName {
		case .fullName, .dateOfBirth, .companyName, .emailAddress, .phoneNumber, .url, .postalAddress, .creditCard: break
		}
	}

	mutating func remove(ids: Set<PersonaDataEntryID>) {
		ids.forEach {
			remove(id: $0)
		}
	}
}
