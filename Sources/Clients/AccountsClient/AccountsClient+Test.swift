import ClientPrelude

extension DependencyValues {
	public var accountsClient: AccountsClient {
		get { self[AccountsClient.self] }
		set { self[AccountsClient.self] = newValue }
	}
}

// MARK: - AccountsClient + TestDependencyKey
extension AccountsClient: TestDependencyKey {
	public static let noop = Self(
		getAccountsOnCurrentNetwork: { throw NoopError() },
		accountsOnCurrentNetwork: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getAccountsOnNetwork: { _ in throw NoopError() },
		createUnsavedVirtualAccount: { _ in throw NoopError() },
		saveVirtualAccount: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false },
		migrateOlympiaSoftwareAccountsToBabylon: { _ in throw NoopError() }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		createUnsavedVirtualAccount: unimplemented("\(Self.self).createUnsavedVirtualAccount"),
		saveVirtualAccount: unimplemented("\(Self.self).saveVirtualAccount"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork"),
		migrateOlympiaSoftwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaSoftwareAccountsToBabylon")
	)
}
