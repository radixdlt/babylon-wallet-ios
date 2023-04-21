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
		personas: unimplemented("\(Self.self).personas"),
		getPersonas: unimplemented("\(Self.self).getPersonas"),
		updatePersona: unimplemented("\(Self.self).updatePersona"),
		newUnsavedVirtualPersonaControlledByDeviceFactorSource: unimplemented("\(Self.self).newUnsavedVirtualPersonaControlledByDeviceFactorSource"),
		newUnsavedVirtualPersonaControlledByLedgerFactorSource: unimplemented("\(Self.self).newUnsavedVirtualPersonaControlledByLedgerFactorSource"),
		saveVirtualPersona: unimplemented("\(Self.self).saveVirtualPersona"),
		hasAnyPersonaOnAnyNetwork: unimplemented("\(Self.self).hasAnyPersonaOnAnyNetwork")
	)
	public static let noop = Self(
		personas: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getPersonas: { .init() },
		updatePersona: { _ in throw NoopError() },
		newUnsavedVirtualPersonaControlledByDeviceFactorSource: { _ in throw NoopError() },
		newUnsavedVirtualPersonaControlledByLedgerFactorSource: { _ in throw NoopError() },
		saveVirtualPersona: { _ in },
		hasAnyPersonaOnAnyNetwork: { true }
	)
}
