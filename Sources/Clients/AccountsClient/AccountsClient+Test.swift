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
		getAccountsOnCurrentNetwork: { fatalError("impl me") },
		accountsOnCurrentNetwork: { fatalError("impl me") },
		createUnsavedVirtualAccount: { _ in throw NoopError() },
		saveVirtualAccount: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		createUnsavedVirtualAccount: unimplemented("\(Self.self).createUnsavedVirtualAccount"),
		saveVirtualAccount: unimplemented("\(Self.self).saveVirtualAccount"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork")
	)
}
