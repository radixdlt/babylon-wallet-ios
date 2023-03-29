import ClientPrelude
import Cryptography
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var getPersonas: GetPersonas
	public var updatePersona: UpdatePersona
	public var createUnsavedVirtualPersona: CreateUnsavedVirtualPersona
	public var saveVirtualPersona: SaveVirtualPersona
	public var hasAnyPersonaOnAnyNetworks: HasAnyPersonaOnAnyNetworks
	public init(
		getPersonas: @escaping GetPersonas,
		updatePersona: @escaping UpdatePersona,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		saveVirtualPersona: @escaping SaveVirtualPersona,
		hasAnyPersonaOnAnyNetworks: @escaping HasAnyPersonaOnAnyNetworks
	) {
		self.getPersonas = getPersonas
		self.updatePersona = updatePersona
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.saveVirtualPersona = saveVirtualPersona
		self.hasAnyPersonaOnAnyNetworks = hasAnyPersonaOnAnyNetworks
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias HasAnyPersonaOnAnyNetworks = @Sendable () async -> Bool
	public typealias UpdatePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias SaveVirtualPersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias CreateUnsavedVirtualPersona = @Sendable (CreateVirtualEntityRequest) async throws -> Profile.Network.Persona
}
