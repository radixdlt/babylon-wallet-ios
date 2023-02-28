import ClientPrelude

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static let liveValue = Self(getAccounts: { fatalError() })
}
