import ClientPrelude
import Cryptography
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var getPersonas: GetPersonas
	public var createUnsavedVirtualPersona: CreateUnsavedVirtualPersona
	public var saveVirtualPersona: SaveVirtualPersona

	public init(
		getPersonas: @escaping GetPersonas,
		createUnsavedVirtualPersona: @escaping CreateUnsavedVirtualPersona,
		saveVirtualPersona: @escaping SaveVirtualPersona
	) {
		self.getPersonas = getPersonas
		self.createUnsavedVirtualPersona = createUnsavedVirtualPersona
		self.saveVirtualPersona = saveVirtualPersona
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias GetPersonas = @Sendable () async throws -> OnNetwork.Personas
	public typealias SaveVirtualPersona = @Sendable (OnNetwork.Persona) async throws -> Void
	public typealias CreateUnsavedVirtualPersona = @Sendable (CreateVirtualEntityRequest) async throws -> OnNetwork.Persona
}
