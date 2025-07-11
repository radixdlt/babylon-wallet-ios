
extension DependencyValues {
	var deviceFactorSourceClient: DeviceFactorSourceClient {
		get { self[DeviceFactorSourceClient.self] }
		set { self[DeviceFactorSourceClient.self] = newValue }
	}
}

// MARK: - DeviceFactorSourceClient + TestDependencyKey
extension DeviceFactorSourceClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let noop = Self(
		controlledEntities: { _ in [] },
		entitiesInBadState: { throw NoopError() },
		derivePublicKeys: { _ in throw NoopError() }
	)

	static let testValue = Self(
		controlledEntities: unimplemented("\(Self.self).controlledEntities"),
		entitiesInBadState: unimplemented("\(Self.self).entitiesInBadState"),
		derivePublicKeys: unimplemented("\(Self.self).derivePublicKeys")
	)
}

private extension AddressesOfEntitiesInBadState {
	static var empty: Self {
		.init(accounts: [], hiddenAccounts: [], personas: [], hiddenPersonas: [])
	}
}
