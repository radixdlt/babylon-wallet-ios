import IdentifiedCollections
import Sargon

// MARK: - PersonasClient
struct PersonasClient {
	var personas: PersonasUpdates
	var getPersonas: GetPersonas
	var getPersonasOnNetwork: GetPersonasOnNetwork
	var getHiddenPersonasOnCurrentNetwork: GetHiddenPersonasOnCurrentNetwork
	var updatePersona: UpdatePersona

	var saveVirtualPersona: SaveVirtualPersona
	var hasSomePersonaOnAnyNetwork: HasSomePersonaOnAnyNetworks
	var hasSomePersonaOnCurrentNetwork: HasSomePersonaOnCurrentNetwork

	var personaUpdates: PersonaUpdates
}

extension PersonasClient {
	typealias PersonasUpdates = @Sendable () async -> AnyAsyncSequence<Personas>
	typealias GetPersonas = @Sendable () async throws -> Personas
	typealias GetPersonasOnNetwork = @Sendable (NetworkID) async -> Personas
	typealias GetHiddenPersonasOnCurrentNetwork = @Sendable () async throws -> Personas
	typealias HasSomePersonaOnAnyNetworks = @Sendable () async -> Bool
	typealias HasSomePersonaOnCurrentNetwork = @Sendable () async -> Bool
	typealias UpdatePersona = @Sendable (Persona) async throws -> Void
	typealias SaveVirtualPersona = @Sendable (Persona) async throws -> Void
	typealias PersonaUpdates = @Sendable (IdentityAddress) async -> AnyAsyncSequence<Persona>
}

extension PersonasClient {
	func getPersona(id: Persona.ID) async throws -> Persona {
		let personas = try await getPersonas()
		guard let persona = personas[id: id] else {
			throw PersonaNotFoundError(id: id)
		}

		return persona
	}

	struct PersonaNotFoundError: Error {
		let id: Persona.ID
	}

	func determinePersonaPrimacy() async -> PersonaPrimacy {
		let hasSomePersonaOnAnyNetwork = await hasSomePersonaOnAnyNetwork()
		let hasSomePersonaOnCurrentNetwork = await hasSomePersonaOnCurrentNetwork()
		let isFirstPersonaOnAnyNetwork = !hasSomePersonaOnAnyNetwork
		let isFirstPersonaOnCurrentNetwork = !hasSomePersonaOnCurrentNetwork

		return PersonaPrimacy(
			firstOnAnyNetwork: isFirstPersonaOnAnyNetwork,
			firstOnCurrent: isFirstPersonaOnCurrentNetwork
		)
	}
}
