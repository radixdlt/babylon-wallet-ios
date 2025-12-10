extension DependencyValues {
	var accessControllerClient: AccessControllerClient {
		get { self[AccessControllerClient.self] }
		set { self[AccessControllerClient.self] = newValue }
	}
}

// MARK: - AccessControllerClient + TestDependencyKey
extension AccessControllerClient: TestDependencyKey {
	static let previewValue: Self = .noop

	static let noop = Self(
		getAllAccessControllerStateDetails: { [] },
		getAccessControllerStateDetails: { _ in AccessControllerStateDetails(address: newAccessControllerAddressSampleStokenet(), timedRecoveryState: nil, xrdBalance: .zero) },
		accessControllerStateDetailsUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		accessControllerUpdates: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		forceRefresh: {}
	)

	static let testValue = Self(
		getAllAccessControllerStateDetails: unimplemented("\(Self.self).getAllAccessControllerStateDetails"),
		getAccessControllerStateDetails: unimplemented("\(Self.self).getAccessControllerStateDetails"),
		accessControllerStateDetailsUpdates: unimplemented("\(Self.self).accessControllerStateDetailsUpdates", placeholder: noop.accessControllerStateDetailsUpdates),
		accessControllerUpdates: unimplemented("\(Self.self).accessControllerUpdates", placeholder: noop.accessControllerUpdates),
		forceRefresh: unimplemented("\(Self.self).forceRefresh", placeholder: noop.forceRefresh)
	)
}
