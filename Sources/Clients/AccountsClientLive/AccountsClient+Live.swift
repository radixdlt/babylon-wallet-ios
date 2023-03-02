import AccountsClient
import ClientPrelude
import ProfileStore

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(profileStore: ProfileStore = .shared) -> Self {
		Self(
			getAccountsOnCurrentNetwork: { await profileStore.network.accounts },
			accountsOnCurrentNetwork: { await profileStore.accountValues() },
			getAccountsOnNetwork: { try await profileStore.profile.onNetwork(id: $0).accounts },
			createUnsavedVirtualAccount: { request in
				try await profileStore.profile.createNewUnsavedVirtualEntity(request: request)
			},
			saveVirtualAccount: { account in
				try await profileStore.updating {
					try $0.addAccount(account)
				}
			},
			getAccountByAddress: { address in
				try await profileStore.network.entity(address: address)
			},
			hasAccountOnNetwork: { networkID in
				do {
					let network = try await profileStore.profile.onNetwork(id: networkID)
					// N.B. `accounts` is NonEmpty so `isEmpty` should always evaluate to `false`.
					return !network.accounts.isEmpty
				} catch {
					return false
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
