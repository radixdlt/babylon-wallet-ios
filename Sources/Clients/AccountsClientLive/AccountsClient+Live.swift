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
			migrateOlympiaAccountsToBabylon: { request in

				let olympiaFactorSource = request.olympiaFactorSource
				let nextDerivationAccountIndex = request.nextDerivationAccountIndex

				let sortedOlympia = request.olympiaAccounts.sorted(by: \.addressIndex)

				let networkID = Radix.Gateway.default.network.id // we import to the default network, not the current.

				var accountsSet = OrderedSet<MigratedAccounts.MigratedAccount>()
				for olympiaAccount in sortedOlympia {
					let publicKey = SLIP10.PublicKey.ecdsaSecp256k1(olympiaAccount.publicKey)
					let address = try Profile.Network.Account.deriveAddress(networkID: networkID, publicKey: publicKey)
					let factorInstance = FactorInstance(
						factorSourceID: olympiaFactorSource.hdOnDeviceFactorSource.id,
						publicKey: publicKey,
						derivationPath: olympiaAccount.path.wrapAsDerivationPath()
					)
					let babylon = Profile.Network.Account(
						networkID: networkID,
						address: address,
						securityState: .unsecured(.init(genesisFactorInstance: factorInstance)),
						appearanceID: .init(rawValue: UInt8(olympiaAccount.addressIndex)) ?? ._0,
						displayName: olympiaAccount.displayName ?? "Unnamned olympia account \(olympiaAccount.addressIndex)"
					)
					let migrated = MigratedAccounts.MigratedAccount(olympia: olympiaAccount, babylon: babylon)
					accountsSet.append(migrated)
				}
				let accounts = NonEmpty<OrderedSet<MigratedAccounts.MigratedAccount>>(rawValue: accountsSet)!
				return try MigratedAccounts(
					networkID: networkID,
					accounts: accounts,
					nextDerivationAccountIndex: nextDerivationAccountIndex
				)
			}
		)
	}

	public static let liveValue: Self = .live()
}
