
extension DependencyValues {
	public var deviceFactorSourceClient: DeviceFactorSourceClient {
		get { self[DeviceFactorSourceClient.self] }
		set { self[DeviceFactorSourceClient.self] = newValue }
	}
}

// MARK: - DeviceFactorSourceClient + TestDependencyKey
extension DeviceFactorSourceClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let noop = Self(
		publicKeysFromOnDeviceHD: { _ in throw NoopError() },
		signatureFromOnDeviceHD: { _ in throw NoopError() },
		isAccountRecoveryNeeded: { false },
		entitiesControlledByFactorSource: { _, _ in throw NoopError() },
		controlledEntities: { _ in [] },
		entitiesInBadState: { throw NoopError() }
	)

	public static let testValue = Self(
		publicKeysFromOnDeviceHD: unimplemented("\(Self.self).publicKeysFromOnDeviceHD"),
		signatureFromOnDeviceHD: unimplemented("\(Self.self).signatureFromOnDeviceHD"),
		isAccountRecoveryNeeded: unimplemented("\(Self.self).isAccountRecoveryNeeded"),
		entitiesControlledByFactorSource: unimplemented("\(Self.self).entitiesControlledByFactorSource"),
		controlledEntities: unimplemented("\(Self.self).controlledEntities"),
		entitiesInBadState: unimplemented("\(Self.self).entitiesInBadState")
	)
}

private extension AddressesOfEntitiesInBadState {
	static var empty: Self {
		.init(accounts: [], hiddenAccounts: [], personas: [], hiddenPersonas: [])
	}
}
