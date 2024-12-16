import Foundation

extension DependencyValues {
	var accountLockersClient: AccountLockersClient {
		get { self[AccountLockersClient.self] }
		set { self[AccountLockersClient.self] = newValue }
	}
}

// MARK: - AccountLockersClient + TestDependencyKey
extension AccountLockersClient: TestDependencyKey {
	static let previewValue: Self = .noop

	static let noop = Self(
		startMonitoring: {},
		claims: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		dappsWithClaims: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		claimContent: { _ in },
		forceRefresh: {}
	)

	static let testValue = Self(
		startMonitoring: unimplemented("\(Self.self).startMonitoring"),
		claims: unimplemented("\(Self.self).claims", placeholder: noop.claims),
		dappsWithClaims: unimplemented("\(Self.self).dappsWithClaims", placeholder: noop.dappsWithClaims),
		claimContent: unimplemented("\(Self.self).claimContent"),
		forceRefresh: unimplemented("\(Self.self).forceRefresh")
	)
}
