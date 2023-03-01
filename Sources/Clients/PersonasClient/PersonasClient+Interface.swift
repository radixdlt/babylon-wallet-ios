import ClientPrelude
import Profile

// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var getPersonas: GetPersonas
	public init(getPersonas: @escaping GetPersonas) {
		self.getPersonas = getPersonas
	}
}

// MARK: PersonasClient.GetPersonas
extension PersonasClient {
	public typealias GetPersonas = @Sendable () async throws -> OnNetwork.Personas
}
