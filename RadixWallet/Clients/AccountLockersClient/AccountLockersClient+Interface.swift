import Foundation

// MARK: - AccountLockersClient
public struct AccountLockersClient: DependencyKey, Sendable {
	public let startMonitoring: StartMonitoring

	/// Async sequence with the AccountLockerClaimDetails for a given Account
	public let accountClaims: AccountClaims

	/// Async sequence with the set of dapps that have at least one AccountLockerClaimDetails associated to it.
	public let dappsWithClaims: DappsWithClaims
}

// MARK: AccountLockersClient.StartMonitoring
extension AccountLockersClient {
	public typealias StartMonitoring = @Sendable () async throws -> Void
	public typealias AccountClaims = @Sendable (AccountAddress) async -> AnyAsyncSequence<[AccountLockerClaimDetails]>
	public typealias DappsWithClaims = @Sendable () async -> AnyAsyncSequence<[String]>
}

// MARK: - AccountLockerClaimDetails
/// A struct holding the details for the pending claims of a given locker address & account address.
public struct AccountLockerClaimDetails: Sendable, Hashable, Codable {
	let lockerAddress: String
	let accountAddress: String
	let dappDefinitionAddress: String
	let dappName: String?
	let lastTouchedAtStateVersion: Int64
	let claims: [GatewayAPI.AccountLockerVaultCollectionItem]
}
