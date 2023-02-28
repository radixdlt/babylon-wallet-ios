import ClientPrelude

import ProfileStore
extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAccounts: { await profileStore.network },
			values: { fatalError() }
		)
	}
}
