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

		let nextAccountIndex: NextAccountIndex = { maybeNetworkID in
			let currentNetworkID = await getCurrentNetworkID()
			let networkID = maybeNetworkID ?? currentNetworkID
			let index = await (try? profileStore.profile.network(id: networkID).nextAccountIndex()) ?? 0
			return HD.Path.Component.Child.Value(index)
		}

		return Self(
			getCurrentNetworkID: getCurrentNetworkID,
			nextAccountIndex: nextAccountIndex,
			getAccountsOnCurrentNetwork: getAccountsOnCurrentNetwork,
			accountsOnCurrentNetwork: { await profileStore.accountValues() },
			accountUpdates: { address in
				await profileStore.accountValues().compactMap {
					$0.first { $0.address == address }
				}
				.eraseToAnyAsyncSequence()
			},
			getAccountsOnNetwork: getAccountsOnNetwork,
			newVirtualAccount: { request in
				let networkID = request.networkID
				let numberOfExistingAccounts = await nextAccountIndex(networkID)
				return try Profile.Network.Account(
					networkID: networkID,
					index: .init(numberOfExistingAccounts),
					factorInstance: request.factorInstance,
					displayName: request.name,
					extraProperties: .init(numberOfAccountsOnNetwork: .init(numberOfExistingAccounts))
				)
			},
			saveVirtualAccounts: saveVirtualAccounts,
			getAccountByAddress: { address in
				try await profileStore.network().entity(address: address)
			},
			hasAccountOnNetwork: { networkID in
				do {
					let network = try await profileStore.profile.network(id: networkID)
					// N.B. `accounts` is NonEmpty so `isEmpty` should always evaluate to `false`.
					return network.hasAnyAccount()
				} catch {
					return false
				}
			},
			updateAccount: { updatedAccount in
				try await profileStore.updating {
					try $0.updateAccount(updatedAccount)
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
