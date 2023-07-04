import AccountsClient
import ClientPrelude
import Cryptography
import ProfileStore

// MARK: - AccountsClient + DependencyKey
extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(
		profileStore getProfileStore: @escaping @Sendable () async -> ProfileStore = { await .shared }
	) -> Self {
		let saveVirtualAccount: SaveVirtualAccount = { request in
			try await getProfileStore().updating {
				try $0.addAccount(request.account)
			}
		}

		let getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork = {
			try await getProfileStore().network().accounts
		}

		let getCurrentNetworkID: GetCurrentNetworkID = { await getProfileStore().profile.networkID }

		let getAccountsOnNetwork: GetAccountsOnNetwork = { try await getProfileStore().profile.network(id: $0).accounts }

		let nextAccountIndex: NextAccountIndex = { maybeNetworkID in
			let currentNetworkID = await getCurrentNetworkID()
			let networkID = maybeNetworkID ?? currentNetworkID
			let index = await (try? getAccountsOnNetwork(networkID).count) ?? 0
			return HD.Path.Component.Child.Value(index)
		}

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			nextAccountIndex: nextAccountIndex,
			getAccountsOnCurrentNetwork: getAccountsOnCurrentNetwork,
			accountsOnCurrentNetwork: { await getProfileStore().accountValues() },
			getAccountsOnNetwork: getAccountsOnNetwork,
			newVirtualAccount: { request in
				let networkID = request.networkID
				let profile = await getProfileStore().profile
				let numberOfExistingAccounts = await nextAccountIndex(networkID)
				return try Profile.Network.Account(
					networkID: networkID,
					index: .init(numberOfExistingAccounts),
					factorInstance: request.factorInstance,
					displayName: request.name,
					extraProperties: .init(numberOfAccountsOnNetwork: .init(numberOfExistingAccounts))
				)
			},
			saveVirtualAccount: saveVirtualAccount,
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
			updateAccount: { updatedAccount in
				try await getProfileStore().updating {
					try $0.updateAccount(updatedAccount)
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
