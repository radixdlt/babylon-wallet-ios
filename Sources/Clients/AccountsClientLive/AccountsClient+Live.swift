import AccountsClient
import ClientPrelude
import ProfileStore

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAccountsOnCurrentNetwork: { await profileStore.network.accounts },
			accountsOnCurrentNetwork: { await profileStore.accountValues() },
			createUnsavedVirtualAccount: { _ in fatalError("impl me") },
			saveVirtualAccount: { _ in fatalError("impl me") }
		)
	}

	public static let liveValue: Self = .live()
}
