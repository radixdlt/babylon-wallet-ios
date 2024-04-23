import IdentifiedCollections
import Sargon

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
	public typealias GetAuthorizedDapps = @Sendable () async throws -> IdentifiedArrayOf<AuthorizedDapp>
	public typealias DetailsForAuthorizedDapp = @Sendable (AuthorizedDapp) async throws -> ProfileNetwork.AuthorizedDappDetailed
	public typealias AddAuthorizedDapp = @Sendable (AuthorizedDapp) async throws -> Void
	public typealias UpdateOrAddAuthorizedDapp = @Sendable (AuthorizedDapp) async throws -> Void
	public typealias ForgetAuthorizedDapp = @Sendable (AuthorizedDapp.ID, NetworkID?) async throws -> Void
	public typealias UpdateAuthorizedDapp = @Sendable (AuthorizedDapp) async throws -> Void
	public typealias DeauthorizePersonaFromDapp = @Sendable (Persona.ID, AuthorizedDapp.ID, NetworkID) async throws -> Void
}

extension AuthorizedDappsClient {
	public func getDetailedDapp(
		_ id: AuthorizedDapp.ID
	) async throws -> ProfileNetwork.AuthorizedDappDetailed {
		let dApps = try await getAuthorizedDapps()
		guard let dApp = dApps[id: id] else {
			throw AuthorizedDappDoesNotExists()
		}
		return try await detailsForAuthorizedDapp(dApp)
	}

	public func getDappsAuthorizedByPersona(
		_ id: Persona.ID
	) async throws -> IdentifiedArrayOf<AuthorizedDapp> {
		try await getAuthorizedDapps().filter { dapp in dapp.referencesToAuthorizedPersonas.contains(where: { authPersona in authPersona.id == id }) }
	}

	public func removeBrokenReferencesToSharedPersonaData(
		personaCurrent: Persona,
		personaUpdated: Persona
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
			}
		}
	}

	public func isDappAuthorized(_ address: DappDefinitionAddress) async -> Bool {
		await (try? getAuthorizedDapps().contains { $0.id == address }) ?? false
	}
}
