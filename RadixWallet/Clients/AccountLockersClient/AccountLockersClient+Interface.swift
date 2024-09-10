import Foundation

// MARK: - AccountLockersClient
public struct AccountLockersClient: DependencyKey, Sendable {
	/// Start monitoring the account locker claims.
	public let startMonitoring: StartMonitoring

	/// Async sequence with the AccountLockerClaimDetails for a given Account
	public let accountClaims: AccountClaims

	/// Async sequence with the set of dapps that have at least one AccountLockerClaimDetails associated to it.
	public let dappsWithClaims: DappsWithClaims

	/// Claim the content for a given account and locker
	public let claimContent: ClaimContent

	/// To be called when we want to trigger a check on the account locker claims.
	public let forceRefresh: ForceRefresh
}

// MARK: AccountLockersClient.StartMonitoring
extension AccountLockersClient {
	public typealias StartMonitoring = @Sendable () async throws -> Void
	public typealias AccountClaims = @Sendable (AccountAddress) async -> AnyAsyncSequence<[AccountLockerClaimDetails]>
	public typealias DappsWithClaims = @Sendable () async -> AnyAsyncSequence<[DappDefinitionAddress]>
	public typealias ClaimContent = @Sendable (AccountLockerClaimDetails) async throws -> Void
	public typealias ForceRefresh = @Sendable () -> Void
}
