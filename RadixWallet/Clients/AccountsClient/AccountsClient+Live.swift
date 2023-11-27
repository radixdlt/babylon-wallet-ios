// MARK: - AccountsClient + DependencyKey

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		let saveVirtualAccounts: SaveVirtualAccounts = { accounts in
			try await profileStore.updating {
				for account in accounts {
					try $0.addAccount(account)
				}
			}
		}

		let getCurrentNetworkID: GetCurrentNetworkID = { await profileStore.profile.networkID }

		let getAccountsOnNetwork: GetAccountsOnNetwork = {
			try await profileStore.profile.network(id: $0).getAccounts()
		}

		let getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork = {
			try await getAccountsOnNetwork(getCurrentNetworkID())
		}

		let nextAppearanceID: NextAppearanceID = { maybeNetworkID, maybeOffset in
			let offset = maybeOffset ?? 0
			let currentNetworkID = await getCurrentNetworkID()
			let networkID = maybeNetworkID ?? currentNetworkID
			let numberOfAccounts = await (try? profileStore.profile.network(id: networkID).numberOfAccountsIncludingHidden) ?? 0
			return Profile.Network.Account.AppearanceID.fromNumberOfAccounts(numberOfAccounts)
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { networkID in
			do {
				let network = try await profileStore.profile.network(id: networkID)
				// N.B. `accounts` is NonEmpty so `isEmpty` should always evaluate to `false`.
				return network.hasSomeAccount()
			} catch {
				return false
			}
		}

		let getHiddenAccountsOnCurrentNetwork: GetHiddenAccountsOnCurrentNetwork = {
			try await profileStore.profile.network(id: getCurrentNetworkID()).getHiddenAccounts()
		}

		let accountsOnCurrentNetwork: AccountsOnCurrentNetwork = { await profileStore.accountValues() }

		let accountUpdates: AccountUpdates = { address in
			await profileStore.accountValues().compactMap {
				$0.first { $0.address == address }
			}
			.eraseToAnyAsyncSequence()
		}

		let newVirtualAccount: NewVirtualAccount = { request in
			let networkID = request.networkID
			let appearanceID = await nextAppearanceID(networkID, nil)
			return try Profile.Network.Account(
				networkID: networkID,
				factorInstance: request.factorInstance,
				displayName: request.name,
				extraProperties: .init(appearanceID: appearanceID)
			)
		}

		let getAccountByAddress: GetAccountByAddress = { address in
			try await profileStore.network().entity(address: address)
		}

		let updateAccount: UpdateAccount = { updatedAccount in
			try await profileStore.updating {
				try $0.updateAccount(updatedAccount)
			}
		}

		#if DEBUG
		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			nextAppearanceID: nextAppearanceID,
			getAccountsOnCurrentNetwork: getAccountsOnCurrentNetwork,
			getHiddenAccountsOnCurrentNetwork: getHiddenAccountsOnCurrentNetwork,
			accountsOnCurrentNetwork: accountsOnCurrentNetwork,
			accountUpdates: accountUpdates,
			getAccountsOnNetwork: getAccountsOnNetwork,
			newVirtualAccount: newVirtualAccount,
			saveVirtualAccounts: saveVirtualAccounts,
			getAccountByAddress: getAccountByAddress,
			hasAccountOnNetwork: hasAccountOnNetwork,
			updateAccount: updateAccount,
			debugOnlyDeleteAccount: { account in
				try await profileStore.updating {
					try $0.deleteAccount(account)
				}
			}
		)
		#else
		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			nextAppearanceID: nextAppearanceID,
			getAccountsOnCurrentNetwork: getAccountsOnCurrentNetwork,
			getHiddenAccountsOnCurrentNetwork: getHiddenAccountsOnCurrentNetwork,
			accountsOnCurrentNetwork: accountsOnCurrentNetwork,
			accountUpdates: accountUpdates,
			getAccountsOnNetwork: getAccountsOnNetwork,
			newVirtualAccount: newVirtualAccount,
			saveVirtualAccounts: saveVirtualAccounts,
			getAccountByAddress: getAccountByAddress,
			hasAccountOnNetwork: hasAccountOnNetwork,
			updateAccount: updateAccount
		)
		#endif
	}

	public static let liveValue: Self = .live()
}
