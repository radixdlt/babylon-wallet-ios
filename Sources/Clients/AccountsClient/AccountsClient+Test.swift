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
		getAccounts: { fatalError("impl me") },
		values: { fatalError() }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getAccounts: unimplemented("\(Self.self).getAccounts"),
		values: unimplemented("\(Self.self).values")
	)
}
