// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var nextPersonaIndex: NextPersonaIndex

	public var personas: Personas
	public var getPersonas: GetPersonas
	public var getPersonasOnNetwork: GetPersonasOnNetwork
	public var updatePersona: UpdatePersona

	public var saveVirtualPersona: SaveVirtualPersona
	public var hasAnyPersonaOnAnyNetwork: HasAnyPersonaOnAnyNetworks

	public init(
		personas: @escaping Personas,
		nextPersonaIndex: @escaping NextPersonaIndex,
		getPersonas: @escaping GetPersonas,
		getPersonasOnNetwork: @escaping GetPersonasOnNetwork,
		updatePersona: @escaping UpdatePersona,
		saveVirtualPersona: @escaping SaveVirtualPersona,
		hasAnyPersonaOnAnyNetwork: @escaping HasAnyPersonaOnAnyNetworks
	) {
		self.personas = personas
		self.nextPersonaIndex = nextPersonaIndex
		self.getPersonas = getPersonas
		self.getPersonasOnNetwork = getPersonasOnNetwork
		self.updatePersona = updatePersona
		self.saveVirtualPersona = saveVirtualPersona
		self.hasAnyPersonaOnAnyNetwork = hasAnyPersonaOnAnyNetwork
	}
}

extension PersonasClient {
	public typealias NextPersonaIndex = @Sendable (NetworkID?) async -> HD.Path.Component.Child.Value
	public typealias Personas = @Sendable () async -> AnyAsyncSequence<Profile.Network.Personas>
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias GetPersonasOnNetwork = @Sendable (NetworkID) async -> Profile.Network.Personas
	public typealias HasAnyPersonaOnAnyNetworks = @Sendable () async -> Bool
	public typealias UpdatePersona = @Sendable (Profile.Network.Persona) async throws -> Void
	public typealias SaveVirtualPersona = @Sendable (Profile.Network.Persona) async throws -> Void
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
