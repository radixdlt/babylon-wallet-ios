import ClientPrelude

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	public var getAccounts: GetAccounts
}

// MARK: AccountsClient.GetAccounts
extension AccountsClient {
	public typealias GetAccounts = @Sendable () async -> OnNetwork.Accounts
}
