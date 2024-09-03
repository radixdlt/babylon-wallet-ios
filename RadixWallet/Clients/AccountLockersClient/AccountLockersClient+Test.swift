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
		accountClaims: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		dappsWithClaims: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		claimContent: { _ in }
	)

	public static let testValue = Self(
		startMonitoring: unimplemented("\(Self.self).startMonitoring"),
		accountClaims: unimplemented("\(Self.self).accountClaims"),
		dappsWithClaims: unimplemented("\(Self.self).dappsWithClaims"),
		claimContent: unimplemented("\(Self.self).claimContent")
	)
}
