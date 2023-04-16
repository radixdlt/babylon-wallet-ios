import ClientPrelude
import Cryptography
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var personas: Personas
	public var getPersonas: GetPersonas
	public var updatePersona: UpdatePersona
	public var createUnsavedVirtualPersona: CreateUnsavedVirtualPersona
	public var saveVirtualPersona: SaveVirtualPersona
	public var hasAnyPersonaOnAnyNetwork: HasAnyPersonaOnAnyNetworks

	public init(
		personas: @escaping Personas,
		getPersonas: @escaping GetPersonas,
		updatePersona: @escaping UpdatePersona,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		saveVirtualPersona: @escaping SaveVirtualPersona,
		hasAnyPersonaOnAnyNetwork: @escaping HasAnyPersonaOnAnyNetworks
	) {
		self.personas = personas
		self.getPersonas = getPersonas
		self.updatePersona = updatePersona
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.saveVirtualPersona = saveVirtualPersona
		self.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias Personas = @Sendable () async -> AnyAsyncSequence<Profile.Network.Personas>
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias HasAnyPersonaOnAnyNetworks = @Sendable () async -> Bool
	public typealias UpdatePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias SaveVirtualPersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias CreateUnsavedVirtualPersona = @Sendable (CreateVirtualEntityRequest) async throws -> Profile.Network.Persona
}

extension PersonasClient {
	public func getPersona(id: Profile.Network.Persona.ID) async throws -> Profile.Network.Persona {
		let personas = try await getPersonas()
		guard let persona = personas[id: id] else {
			throw PersonaNotFoundError(id: id)
		}

		return persona
	}

	public struct PersonaNotFoundError: Error {
		let id: Profile.Network.Persona.ID
	}
}
