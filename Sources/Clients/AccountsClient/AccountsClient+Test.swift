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
		createUnsavedVirtualAccount: { _ in fatalError("impl me") },
		saveVirtualAccount: { _ in fatalError("impl me") }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		createUnsavedVirtualAccount: unimplemented("\(Self.self).createUnsavedVirtualAccount"),
		saveVirtualAccount: unimplemented("\(Self.self).saveVirtualAccount")
	)
}
