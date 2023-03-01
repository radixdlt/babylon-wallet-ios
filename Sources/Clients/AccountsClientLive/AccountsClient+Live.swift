import AccountsClient
import ClientPrelude
import ProfileStore

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAccountsOnCurrentNetwork: { await profileStore.network.accounts },
			accountsOnCurrentNetwork: { await profileStore.accountValues() },
			createUnsavedVirtualAccount: { request in
				try await profileStore.profile.createUnsavedVirtualEntity(request: request)
			},
			saveVirtualAccount: { account in
				try await profileStore.updating {
					try $0.addAccount(account)
				}
			},
			getAccountByAddress: { address in
				try await profileStore.network.entity(address: address)
			}
		)
	}

	public static let liveValue: Self = .live()
}
