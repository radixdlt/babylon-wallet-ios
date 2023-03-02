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
		createUnsavedVirtualPersona: unimplemented("\(Self.self).createUnsavedVirtualPersona"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona")
	)
	public static let noop = Self(
		getPersonas: { .init() },
		createUnsavedVirtualPersona: { _ in throw NoopError() },
		saveVirtualPersona: { _ in }
	)
}
