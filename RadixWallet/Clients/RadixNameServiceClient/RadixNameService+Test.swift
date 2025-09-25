extension DependencyValues {
	public var radixNameService: RadixNameServiceClient {
		get { self[RadixNameServiceClient.self] }
		set { self[RadixNameServiceClient.self] = newValue }
	}
}

// MARK: - RadixNameServiceClient + TestDependencyKey
extension RadixNameServiceClient: TestDependencyKey {
	public static let previewValue = Self(resolveReceiverAccountForDomain: unimplemented("\(Self.self).resolveReceiverAccountForDomain"))
	public static let testValue = Self(resolveReceiverAccountForDomain: unimplemented("\(Self.self).resolveReceiverAccountForDomain"))
}
