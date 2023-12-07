
extension DependencyValues {
	public var accountsClient: AccountsClient {
		get { self[AccountsClient.self] }
		set { self[AccountsClient.self] = newValue }
	}
}

// MARK: - AccountsClient + TestDependencyKey
extension AccountsClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	#if DEBUG
	public static let noop = Self(
		getCurrentNetworkID: { .kisharnet },
		nextAppearanceID: { _, _ in ._0 },
		getAccountsOnCurrentNetwork: { throw NoopError() },
		getHiddenAccountsOnCurrentNetwork: { throw NoopError() },
		accountsOnCurrentNetwork: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		accountUpdates: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAccountsOnNetwork: { _ in throw NoopError() },
		newVirtualAccount: { _ in throw NoopError() },
		saveVirtualAccounts: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false },
		updateAccount: { _ in },
		debugOnlyDeleteAccount: { _ in }
	)

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		nextAppearanceID: unimplemented("\(Self.self).nextAppearanceID"),
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		getHiddenAccountsOnCurrentNetwork: unimplemented("\(Self.self).getHiddenAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		accountUpdates: unimplemented("\(Self.self).accountUpdates"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		newVirtualAccount: unimplemented("\(Self.self).newVirtualAccount"),
		saveVirtualAccounts: unimplemented("\(Self.self).saveVirtualAccounts"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		updateAccount: unimplemented("\(Self.self).updateAccount"),
		debugOnlyDeleteAccount: unimplemented("\(Self.self).debugOnlyDeleteAccount")
	)
	#else
	public static let noop = Self(
		getCurrentNetworkID: { .kisharnet },
		nextAppearanceID: { _, _ in ._0 },
		getAccountsOnCurrentNetwork: { throw NoopError() },
		getHiddenAccountsOnCurrentNetwork: { throw NoopError() },
		accountsOnCurrentNetwork: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		accountUpdates: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAccountsOnNetwork: { _ in throw NoopError() },
		newVirtualAccount: { _ in throw NoopError() },
		saveVirtualAccounts: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false },
		updateAccount: { _ in }
	)

	public static let testValue = Self(
		getCurrentNetworkID: unimplemented("\(Self.self).getCurrentNetworkID"),
		nextAppearanceID: unimplemented("\(Self.self).nextAppearanceID"),
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		getHiddenAccountsOnCurrentNetwork: unimplemented("\(Self.self).getHiddenAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		accountUpdates: unimplemented("\(Self.self).accountUpdates"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		newVirtualAccount: unimplemented("\(Self.self).newVirtualAccount"),
		saveVirtualAccounts: unimplemented("\(Self.self).saveVirtualAccounts"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		updateAccount: unimplemented("\(Self.self).updateAccount")
	)
	#endif
}
