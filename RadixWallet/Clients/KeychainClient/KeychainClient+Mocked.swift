
extension DependencyValues {
	var keychainClient: KeychainClient {
		get { self[KeychainClient.self] }
		set { self[KeychainClient.self] = newValue }
	}
}

// MARK: - KeychainClient + TestDependencyKey
extension KeychainClient: TestDependencyKey {
	static let previewValue = Self.noop

	static var testValue = Self(
		getServiceAndAccessGroup: unimplemented("\(Self.self).getServiceAndAccessGroup", placeholder: noop._getServiceAndAccessGroup),
		containsDataForKey: unimplemented("\(Self.self).containsDataForKey"),
		setDataWithoutAuthForKey: unimplemented("\(Self.self).setDataWithoutAuthForKey"),
		setDataWithAuthForKey: unimplemented("\(Self.self).setDataWithAuthForKey"),
		getDataWithoutAuthForKeySetIfNil: unimplemented("\(Self.self).getDataWithoutAuthForKeySetIfNil"),
		getDataWithAuthForKeySetIfNil: unimplemented("\(Self.self).getDataWithAuthForKeySetIfNil"),
		getDataWithoutAuthForKey: unimplemented("\(Self.self).getDataWithoutAuthForKey"),
		getDataWithAuthForKey: unimplemented("\(Self.self).getDataWithAuthForKey"),
		removeDataForKey: unimplemented("\(Self.self).removeDataForKey"),
		removeAllItems: unimplemented("\(Self.self).removeAllItems"),
		getAllKeysMatchingAttributes: unimplemented("\(Self.self).getAllKeysMatchingAttributes", placeholder: noop.getAllKeysMatchingAttributes),
		keychainChanged: unimplemented("\(Self.self).keychainChanged", placeholder: noop._keychainChanged)
	)

	static let noop: Self = .init(
		getServiceAndAccessGroup: { .init(service: "KeychainClientTest", accessGroup: nil) },
		containsDataForKey: { _, _ in false },
		setDataWithoutAuthForKey: { _, _, _ in throw NoopError() },
		setDataWithAuthForKey: { _, _, _ in throw NoopError() },
		getDataWithoutAuthForKeySetIfNil: { _, _ in throw NoopError() },
		getDataWithAuthForKeySetIfNil: { _, _, _ in throw NoopError() },
		getDataWithoutAuthForKey: { _ in throw NoopError() },
		getDataWithAuthForKey: { _, _ in throw NoopError() },
		removeDataForKey: { _ in throw NoopError() },
		removeAllItems: {},
		getAllKeysMatchingAttributes: { _ in [] },
		keychainChanged: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
