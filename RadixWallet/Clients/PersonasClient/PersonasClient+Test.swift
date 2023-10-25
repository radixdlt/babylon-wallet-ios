
extension DependencyValues {
	public var personasClient: PersonasClient {
		get { self[PersonasClient.self] }
		set { self[PersonasClient.self] = newValue }
	}
}

// MARK: - PersonasClient + TestDependencyKey
extension PersonasClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		personas: unimplemented("\(Self.self).personas"),
		nextPersonaIndex: unimplemented("\(Self.self).nextPersonaIndex"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getPersonasOnNetwork: unimplemented("\(Self.self).getPersonasOnNetwork"),
		updatePersona: unimplemented("\(Self.self).updatePersona"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona"),
		hasAnyPersonaOnAnyNetwork: unimplemented("\(Self.self).hasAnyPersonaOnAnyNetwork"),
		hasAnyPersonaOnCurrentNetwork: unimplemented("\(Self.self).hasAnyPersonaOnCurrentNetwork")
	)
	public static let noop = Self(
		personas: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		nextPersonaIndex: { _ in 0 },
		getPersonas: { .init() },
		getPersonasOnNetwork: { _ in .init() },
		updatePersona: { _ in throw NoopError() },
		saveVirtualPersona: { _ in },
		hasAnyPersonaOnAnyNetwork: { true },
		hasAnyPersonaOnCurrentNetwork: { true }
	)
}
