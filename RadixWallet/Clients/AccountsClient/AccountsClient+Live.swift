// MARK: - AccountsClient + DependencyKey

extension AccountsClient: DependencyKey {
	public typealias Value = AccountsClient

	public static func live(
		profileStore: ProfileStore = .shared
	) -> Self {
		let saveVirtualAccounts: SaveVirtualAccounts = { _ in
//			try await profileStore.updating {
//				for account in accounts {
//					try $0.addAccount(account)
//				}
//			}
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let getCurrentNetworkID: GetCurrentNetworkID = {
//			await profileStore.profile.networkID
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let getAccountsOnNetwork: GetAccountsOnNetwork = { _ in
//			try await profileStore.profile.network(id: $0).getAccounts()
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork = {
//			try await getAccountsOnNetwork(getCurrentNetworkID())
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let nextAppearanceID: NextAppearanceID = { _, _ in
//			let offset = maybeOffset ?? 0
//			let currentNetworkID = await getCurrentNetworkID()
//			let networkID = maybeNetworkID ?? currentNetworkID
//			let numberOfAccounts = await (try? profileStore.profile.network(id: networkID).numberOfAccountsIncludingHidden) ?? 0
//			return AppearanceID.fromNumberOfAccounts(numberOfAccounts + offset)
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let hasAccountOnNetwork: HasAccountOnNetwork = { _ in
//			do {
//				let network = try await profileStore.profile.network(id: networkID)
//				// N.B. `accounts` is NonEmpty so `isEmpty` should always evaluate to `false`.
//				return network.hasSomeAccount()
//			} catch {
//				return false
//			}
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let getHiddenAccountsOnCurrentNetwork: GetHiddenAccountsOnCurrentNetwork = {
//			try await profileStore.profile.network(id: getCurrentNetworkID()).getHiddenAccounts()
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let accountsOnCurrentNetwork: AccountsOnCurrentNetwork = {
//			await profileStore.accountValues()
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let accountUpdates: AccountUpdates = { _ in
//			await profileStore.accountValues().compactMap {
//				$0.first { $0.address == address }
//			}
//			.eraseToAnyAsyncSequence()
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let newVirtualAccount: NewVirtualAccount = { _ in
//			let networkID = request.networkID
//			let appearanceID = await nextAppearanceID(networkID, nil)
//			return try Profile.Network.Account(
//				networkID: networkID,
//				factorInstance: request.factorInstance,
//				displayName: request.name,
//				extraProperties: .init(appearanceID: appearanceID)
//			)
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let getAccountByAddress: GetAccountByAddress = { _ in
//			try await profileStore.network().entity(address: address)
			sargonProfileFinishMigrateAtEndOfStage1()
		}

		let updateAccount: UpdateAccount = { _ in
//			try await profileStore.updating {
//				try $0.updateAccount(updatedAccount)
//			}
			sargonProfileFinishMigrateAtEndOfStage1()
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
