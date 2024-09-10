import Foundation

extension DependencyValues {
	public var accountLockersClient: AccountLockersClient {
		get { self[AccountLockersClient.self] }
		set { self[AccountLockersClient.self] = newValue }
	}
}

// MARK: - AccountLockersClient + TestDependencyKey
extension AccountLockersClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		startMonitoring: {},
		claims: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		dappsWithClaims: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		claimContent: { _ in },
		forceRefresh: {}
	)

	public static let testValue = Self(
		startMonitoring: unimplemented("\(Self.self).startMonitoring"),
		claims: unimplemented("\(Self.self).claims"),
		dappsWithClaims: unimplemented("\(Self.self).dappsWithClaims"),
		claimContent: unimplemented("\(Self.self).claimContent"),
		forceRefresh: unimplemented("\(Self.self).forceRefresh")
	)
}
