import ClientPrelude

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
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		updatePersona: unimplemented("\(Self.self).updatePersona"),
		createUnsavedVirtualPersona: unimplemented("\(Self.self).createUnsavedVirtualPersona"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona"),
		hasAnyPersonaOnAnyNetwork: unimplemented("\(Self.self).hasAnyPersonaOnAnyNetwork")
	)
	public static let noop = Self(
		getPersonas: { .init() },
		updatePersona: { _ in throw NoopError() },
		createUnsavedVirtualPersona: { _ in throw NoopError() },
		saveVirtualPersona: { _ in },
		hasAnyPersonaOnAnyNetwork: { true }
	)
}
