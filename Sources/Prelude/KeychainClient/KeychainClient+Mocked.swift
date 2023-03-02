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
		setDataWithoutAuthForKey: unimplemented("\(Self.self).setDataWithoutAuthForKey"),
		setDataWithAuthForKey: unimplemented("\(Self.self).setDataWithAuthForKey"),
		getDataWithoutAuthForKey: unimplemented("\(Self.self).getDataWithoutAuthForKey"),
		getDataWithAuthForKey: unimplemented("\(Self.self).getDataWithAuthForKey"),
		removeDataForKey: unimplemented("\(Self.self).removeDataForKey"),
		removeAllItems: unimplemented("\(Self.self).removeAllItems")
	)

	public static let noop: Self = .init(
		setDataWithoutAuthForKey: { _ in throw NoopError() },
		setDataWithAuthForKey: { _ in throw NoopError() },
		getDataWithoutAuthForKey: { _ in throw NoopError() },
		getDataWithAuthForKey: { _, _ in throw NoopError() },
		removeDataForKey: { _ in throw NoopError() },
		removeAllItems: {}
	)

	public static let previewValue: Self = .noop
}
