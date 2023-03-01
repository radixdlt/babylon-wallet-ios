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
		getPersonas: unimplemented("\(Self.self).getPersonas")
	)
	public static let noop = Self(
		getPersonas: { .init() }
	)
}
