// MARK: - PersonasClient
public struct PersonasClient: Sendable {
	public var nextPersonaIndex: NextPersonaIndex

	public var personas: Personas
	public var getPersonas: GetPersonas
	public var getPersonasOnNetwork: GetPersonasOnNetwork
	public var getHiddenPersonasOnCurrentNetwork: getHiddenPersonasOnCurrentNetwork
	public var updatePersona: UpdatePersona

	public var saveVirtualPersona: SaveVirtualPersona
	public var hasSomePersonaOnAnyNetwork: HasSomePersonaOnAnyNetworks
	public var hasSomePersonaOnCurrentNetwork: HasSomePersonaOnCurrentNetwork

	public init(
		personas: @escaping Personas,
		nextPersonaIndex: @escaping NextPersonaIndex,
		getPersonas: @escaping GetPersonas,
		getPersonasOnNetwork: @escaping GetPersonasOnNetwork,
		getHiddenPersonasOnCurrentNetwork: @escaping getHiddenPersonasOnCurrentNetwork,
		updatePersona: @escaping UpdatePersona,
		saveVirtualPersona: @escaping SaveVirtualPersona,
		hasSomePersonaOnAnyNetwork: @escaping HasSomePersonaOnAnyNetworks,
		hasSomePersonaOnCurrentNetwork: @escaping HasSomePersonaOnCurrentNetwork
	) {
		self.personas = personas
		self.nextPersonaIndex = nextPersonaIndex
		self.getPersonas = getPersonas
		self.getPersonasOnNetwork = getPersonasOnNetwork
		self.getHiddenPersonasOnCurrentNetwork = getHiddenPersonasOnCurrentNetwork
		self.updatePersona = updatePersona
		self.saveVirtualPersona = saveVirtualPersona
		self.hasSomePersonaOnAnyNetwork = hasSomePersonaOnAnyNetwork
		self.hasSomePersonaOnCurrentNetwork = hasSomePersonaOnCurrentNetwork
	}
}

extension PersonasClient {
	public typealias NextPersonaIndex = @Sendable (NetworkID?) async -> HD.Path.Component.Child.Value
	public typealias Personas = @Sendable () async -> AnyAsyncSequence<Profile.Network.Personas>
	public typealias GetPersonas = @Sendable () async throws -> Profile.Network.Personas
	public typealias GetPersonasOnNetwork = @Sendable (NetworkID) async -> Profile.Network.Personas
	public typealias getHiddenPersonasOnCurrentNetwork = @Sendable () async throws -> Profile.Network.Personas
	public typealias HasSomePersonaOnAnyNetworks = @Sendable () async -> Bool
	public typealias HasSomePersonaOnCurrentNetwork = @Sendable () async -> Bool
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

	public func determinePersonaPrimacy() async -> PersonaPrimacy {
		let hasSomePersonaOnAnyNetwork = await hasSomePersonaOnAnyNetwork()
		let hasSomePersonaOnCurrentNetwork = await hasSomePersonaOnCurrentNetwork()
		let isFirstPersonaOnAnyNetwork = !hasSomePersonaOnAnyNetwork
		let isFirstPersonaOnCurrentNetwork = !hasSomePersonaOnCurrentNetwork

		return PersonaPrimacy(
			firstOnAnyNetwork: isFirstPersonaOnAnyNetwork,
			firstOnCurrent: isFirstPersonaOnCurrentNetwork
		)
	}

	public func shouldWriteDownSeedPhraseForSomePersona() async throws -> Bool {
		try await getPersonas().contains(where: \.shouldWriteDownMnemonic)
	}

	public func shouldWriteDownSeedPhraseForSomePersonaSequence() async -> AnyAsyncSequence<Bool> {
		await personas().map { personas in
			personas.contains(where: \.shouldWriteDownMnemonic)
		}
		.share()
		.eraseToAnyAsyncSequence()
	}
}
