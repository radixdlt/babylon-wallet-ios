import AccountsClient
import ClientPrelude
import ProfileStore

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		Self(
			getAccountsOnCurrentNetwork: {
				try await getProfileStore().network().accounts
			},
			accountsOnCurrentNetwork: { await getProfileStore().accountValues() },
			getAccountsOnNetwork: { try await getProfileStore().profile.network(id: $0).accounts },
			createUnsavedVirtualAccount: { request in
				try await getProfileStore().profile.createNewUnsavedVirtualEntity(request: request)
			},
			saveVirtualAccount: { account in
				try await getProfileStore().updating {
					try $0.addAccount(account)
				}
			},
			getAccountByAddress: { address in
				try await getProfileStore().network().entity(address: address)
			},
			hasAccountOnNetwork: { networkID in
				do {
					let network = try await getProfileStore().profile.network(id: networkID)
					// N.B. `accounts` is NonEmpty so `isEmpty` should always evaluate to `false`.
					return !network.accounts.isEmpty
				} catch {
					return false
				}
			},
			migrateOlympiaAccountsToBabylon: { _ in
				fatalError()
			}
		)
	}

	public static let liveValue: Self = .live()
}
