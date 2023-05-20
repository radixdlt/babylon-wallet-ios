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
				try $0.addAccount(request.account, shouldUpdateFactorSourceNextDerivationIndex: request.shouldUpdateFactorSourceNextDerivationIndex)
			}
		}

		let getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork = {
			try await getProfileStore().network().accounts
		}

		return Self(
			getCurrentNetworkID: { await getProfileStore().profile.networkID },
			getAccountsOnCurrentNetwork: getAccountsOnCurrentNetwork,
			accountsOnCurrentNetwork: { await getProfileStore().accountValues() },
			getAccountsOnNetwork: { try await getProfileStore().profile.network(id: $0).accounts },
			newVirtualAccount: { request in
				let networkID = request.networkID
				let profile = await getProfileStore().profile
				let numberOfExistingAccounts = (try? profile.network(id: networkID))?.accounts.count ?? 0
				return try Profile.Network.Account(
					networkID: networkID,
					factorInstance: request.factorInstance,
					displayName: request.name,
					extraProperties: .init(numberOfAccountsOnNetwork: numberOfExistingAccounts)
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
