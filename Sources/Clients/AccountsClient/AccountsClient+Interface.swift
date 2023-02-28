import ClientPrelude

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	public var getAccounts: GetAccounts
	public var values: Values

	public init(
		getAccounts: @escaping GetAccounts,
		values: @escaping Values
	) {
		self.getAccounts = getAccounts
		self.values = values
	}
}

extension AccountsClient {
	/// async returns the current accounts from Profile as a single value.
	public typealias GetAccounts = @Sendable () async -> OnNetwork.Accounts

	/// async returns an async sequence of accounts from Profile
	public typealias Values = @Sendable () async -> AnyAsyncSequence<OnNetwork.Accounts>
}
