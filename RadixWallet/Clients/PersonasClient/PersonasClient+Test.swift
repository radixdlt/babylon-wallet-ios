
extension DependencyValues {
	var personasClient: PersonasClient {
		get { self[PersonasClient.self] }
		set { self[PersonasClient.self] = newValue }
	}
}

// MARK: - PersonasClient + TestDependencyKey
extension PersonasClient: TestDependencyKey {
	static let previewValue = Self.noop
	static let testValue = Self(
		personas: unimplemented("\(Self.self).personas", placeholder: noop.personas),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		getPersonasOnNetwork: unimplemented("\(Self.self).getPersonasOnNetwork", placeholder: noop.getPersonasOnNetwork),
		getHiddenPersonasOnCurrentNetwork: unimplemented("\(Self.self).getHiddenPersonasOnCurrentNetwork"),
		updatePersona: unimplemented("\(Self.self).updatePersona"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona"),
		hasSomePersonaOnAnyNetwork: unimplemented("\(Self.self).hasSomePersonaOnAnyNetwork", placeholder: noop.hasSomePersonaOnAnyNetwork),
		hasSomePersonaOnCurrentNetwork: unimplemented("\(Self.self).hasSomePersonaOnCurrentNetwork", placeholder: noop.hasSomePersonaOnCurrentNetwork)
	)
	static let noop = Self(
		personas: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getPersonas: { .init() },
		getPersonasOnNetwork: { _ in .init() },
		getHiddenPersonasOnCurrentNetwork: { throw NoopError() },
		updatePersona: { _ in throw NoopError() },
		saveVirtualPersona: { _ in },
		hasSomePersonaOnAnyNetwork: { true },
		hasSomePersonaOnCurrentNetwork: { true }
	)
}
