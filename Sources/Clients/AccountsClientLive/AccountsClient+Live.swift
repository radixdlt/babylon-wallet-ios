import AccountsClient
import ClientPrelude
import ProfileStore

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAccounts: { await profileStore.network.accounts },
			values: { await profileStore.accountValues() }
		)
	}

	public static let liveValue: Self = .live()
}
