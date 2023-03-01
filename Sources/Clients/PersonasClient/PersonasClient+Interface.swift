import ClientPrelude
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var getPersonas: GetPersonas
	public var saveVirtualPersona: SaveVirtualPersona

	public init(
		getPersonas: @escaping GetPersonas,
		saveVirtualPersona: @escaping SaveVirtualPersona
	) {
		self.getPersonas = getPersonas
		self.saveVirtualPersona = saveVirtualPersona
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias GetPersonas = @Sendable () async throws -> OnNetwork.Personas
	public typealias SaveVirtualPersona = @Sendable (OnNetwork.Persona) async throws -> Void
}
