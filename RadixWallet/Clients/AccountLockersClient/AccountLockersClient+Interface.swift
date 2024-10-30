import Foundation

// MARK: - AccountLockersClient
struct AccountLockersClient: DependencyKey, Sendable {
	/// Start monitoring the account locker claims.
	let startMonitoring: StartMonitoring

	/// Async sequence with the `AccountLockerClaimDetails` for every `AccountAddress`
	let claims: Claims

	/// Async sequence with the set of dapps that have at least one AccountLockerClaimDetails associated to it.
	let dappsWithClaims: DappsWithClaims

	/// Claim the content for a given account and locker
	let claimContent: ClaimContent

	/// To be called when we want to trigger a check on the account locker claims.
	let forceRefresh: ForceRefresh
}

// MARK: AccountLockersClient.StartMonitoring
extension AccountLockersClient {
	typealias StartMonitoring = @Sendable () async throws -> Void
	typealias Claims = @Sendable () async -> AnyAsyncSequence<ClaimsPerAccount>
	typealias AccountClaims = @Sendable (AccountAddress) async -> AnyAsyncSequence<[AccountLockerClaimDetails]>
	typealias DappsWithClaims = @Sendable () async -> AnyAsyncSequence<[DappDefinitionAddress]>
	typealias ClaimContent = @Sendable (AccountLockerClaimDetails) async throws -> Void
	typealias ForceRefresh = @Sendable () -> Void
}

extension AccountLockersClient {
	/// Async sequence with the `AccountLockerClaimDetails` for a given `AccountAddress`
	func accountClaims(_ account: AccountAddress) async -> AnyAsyncSequence<[AccountLockerClaimDetails]> {
		await claims().compactMap {
			$0[account]
		}
		.share()
		.eraseToAnyAsyncSequence()
	}
}
