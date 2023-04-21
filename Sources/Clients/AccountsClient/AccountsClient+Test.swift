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
		newUnsavedVirtualAccountControlledByDeviceFactorSource: { _ in throw NoopError() },
		newUnsavedVirtualAccountControlledByLedgerFactorSource: { _ in throw NoopError() },
		saveVirtualAccount: { _ in },
		getAccountByAddress: { _ in throw NoopError() },
		hasAccountOnNetwork: { _ in false }
	)
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		getAccountsOnCurrentNetwork: unimplemented("\(Self.self).getAccountsOnCurrentNetwork"),
		accountsOnCurrentNetwork: unimplemented("\(Self.self).accountsOnCurrentNetwork"),
		getAccountsOnNetwork: unimplemented("\(Self.self).getAccountsOnNetwork"),
		newUnsavedVirtualAccountControlledByDeviceFactorSource: unimplemented("\(Self.self).newUnsavedVirtualAccountControlledByDeviceFactorSource"),
		newUnsavedVirtualAccountControlledByLedgerFactorSource: unimplemented("\(Self.self).newUnsavedVirtualAccountControlledByLedgerFactorSource"),
		saveVirtualAccount: unimplemented("\(Self.self).saveVirtualAccount"),
		getAccountByAddress: unimplemented("\(Self.self).getAccountByAddress"),
		hasAccountOnNetwork: unimplemented("\(Self.self).hasAccountOnNetwork")
	)
}
