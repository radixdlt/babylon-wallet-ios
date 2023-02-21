import Dependencies

extension DependencyValues {
	public var keychainClient: KeychainClient {
		get { self[KeychainClient.self] }
		set { self[KeychainClient.self] = newValue }
	}
}

// MARK: - KeychainClient + TestDependencyKey
extension KeychainClient: TestDependencyKey {
	public static var testValue = Self(
		addDataWithoutAuthForKey: unimplemented("\(Self.self).addDataWithoutAuthForKey"),
		addDataWithAuthForKey: unimplemented("\(Self.self).addDataWithAuthForKey"),
		getDataWithoutAuthForKey: unimplemented("\(Self.self).getDataWithoutAuthForKey"),
		getDataWithAuthForKey: unimplemented("\(Self.self).getDataWithAuthForKey"),
		updateDataWithoutAuthForKey: unimplemented("\(Self.self).updateDataWithoutAuthForKey"),
		updateDataWithAuthForKey: unimplemented("\(Self.self).updateDataWithAuthForKey"),
		removeDataForKey: unimplemented("\(Self.self).removeDataForKey"),
		removeAllItems: unimplemented("\(Self.self).removeAllItems")
	)

	public static let noop: Self = .init(
		addDataWithoutAuthForKey: { _ in throw NoopError() },
		addDataWithAuthForKey: { _ in throw NoopError() },
		getDataWithoutAuthForKey: { _ in throw NoopError() },
		getDataWithAuthForKey: { _, _ in throw NoopError() },
		updateDataWithoutAuthForKey: { _, _ in throw NoopError() },
		updateDataWithAuthForKey: { _, _, _ in throw NoopError() },
		removeDataForKey: { _ in throw NoopError() },
		removeAllItems: {}
	)

	public static let previewValue: Self = .noop
}
