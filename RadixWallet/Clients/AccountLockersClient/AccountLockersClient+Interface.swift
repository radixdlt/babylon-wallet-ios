import Foundation

// MARK: - AccountLockersClient
public struct AccountLockersClient: DependencyKey, Sendable {
	public let startMonitoring: StartMonitoring

	/// Async sequence with the AccountLockerClaims for a given Account
	public let accountClaims: AccountClaims

	/// Async sequence with the set of dapps that have at least one AccountLockerClaim associated to it.
	public let dappsWithClaims: DappsWithClaims
}

// MARK: AccountLockersClient.StartMonitoring
extension AccountLockersClient {
	public typealias StartMonitoring = @Sendable () async throws -> Void
	public typealias AccountClaims = @Sendable (AccountAddress) async -> AnyAsyncSequence<[AccountLockerClaims]>
	public typealias DappsWithClaims = @Sendable () async -> AnyAsyncSequence<[String]>
}
