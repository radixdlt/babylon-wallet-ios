
extension DependencyValues {
	public var accountsClient: AccountsClient {
		get { self[AccountsClient.self] }
		set { self[AccountsClient.self] = newValue }
	}
}

// MARK: - AccountsClient + TestDependencyKey
extension AccountsClient: TestDependencyKey {
	public static let noop = Self(
		getCurrentNetworkID: { .kisharnet },
		nextAccountIndex: { _ in 0 },
		getAccountsOnCurrentNetwork: { throw NoopError() },
		accountsOnCurrentNetwork: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		accountUpdates: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAccountsOnNetwork: { _ in throw NoopError() },
		newVirtualAccount: { _ in throw NoopError() },
		saveVirtualAccount: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false },
		updateAccount: { _ in }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		nextAccountIndex: unimplemented("\(Self.self).nextAccountIndex"),
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		accountUpdates: unimplemented("\(Self.self).accountUpdates"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		newVirtualAccount: unimplemented("\(Self.self).newVirtualAccount"),
		saveVirtualAccount: unimplemented("\(Self.self).saveVirtualAccount"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		updateAccount: unimplemented("\(Self.self).updateAccount")
	)
}
