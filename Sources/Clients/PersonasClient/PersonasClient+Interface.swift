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

	public init(
		personas: @escaping Personas,
		getPersonas: @escaping GetPersonas,
		updatePersona: @escaping UpdatePersona,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		saveVirtualPersona: @escaping SaveVirtualPersona
	) {
		self.personas = personas
		self.getPersonas = getPersonas
		self.updatePersona = updatePersona
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.saveVirtualPersona = saveVirtualPersona
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias Personas = @Sendable () async -> AnyAsyncSequence<Profile.Network.Personas>
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias UpdatePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias SaveVirtualPersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias CreateUnsavedVirtualPersona = @Sendable (CreateVirtualEntityRequest) async throws -> Profile.Network.Persona
}
