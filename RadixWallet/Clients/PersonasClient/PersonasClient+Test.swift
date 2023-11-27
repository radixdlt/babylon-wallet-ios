
extension DependencyValues {
	public var personasClient: PersonasClient {
		get { self[PersonasClient.self] }
		set { self[PersonasClient.self] = newValue }
	}
}

// MARK: - PersonasClient + TestDependencyKey
extension PersonasClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue = Self(
		personas: unimplemented("\(Self.self).personas"),
		nextPersonaIndexForFactorSource: unimplemented("\(Self.self).nextPersonaIndexForFactorSource"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getPersonasOnNetwork: unimplemented("\(Self.self).getPersonasOnNetwork"),
		getHiddenPersonasOnCurrentNetwork: unimplemented("\(Self.self).getHiddenPersonasOnCurrentNetwork"),
		updatePersona: unimplemented("\(Self.self).updatePersona"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona"),
		hasSomePersonaOnAnyNetwork: unimplemented("\(Self.self).hasAnyPersonaOnAnyNetwork"),
		hasSomePersonaOnCurrentNetwork: unimplemented("\(Self.self).hasAnyPersonaOnCurrentNetwork")
	)
	public static let noop = Self(
		personas: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		nextPersonaIndexForFactorSource: { _, _ in 0 },
		getPersonas: { .init() },
		getPersonasOnNetwork: { _ in .init() },
		getHiddenPersonasOnCurrentNetwork: { throw NoopError() },
		updatePersona: { _ in throw NoopError() },
		saveVirtualPersona: { _ in },
		hasSomePersonaOnAnyNetwork: { true },
		hasSomePersonaOnCurrentNetwork: { true }
	)
}
