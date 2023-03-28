import AccountsClient
import ClientPrelude
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
			migrateOlympiaAccountsToBabylon: { olympiaAccounts in
				let sortedOlympia = olympiaAccounts.sorted(by: \.addressIndex)
				let networkID = try await getProfileStore().network().networkID
				var accountsSet = OrderedSet<MigratedAccounts.MigratedAccount>()
				for olympiaAccount in olympiaAccounts {
					fatalError() // do migration
				}
				let accounts = NonEmpty<OrderedSet<MigratedAccounts.MigratedAccount>>(rawValue: accountsSet)!
				let nextIndex = sortedOlympia.last!.addressIndex + 1
				return try MigratedAccounts(
					networkID: networkID,
					accounts: accounts,
					nextDerivationIndexForAccountForOlympiaFactor: Int(nextIndex)
				)
			}
		)
	}

	public static let liveValue: Self = .live()
}

extension OlympiaAccountToMigrate {
	var addressIndex: UInt32 {
		0
	}
}

extension Collection {
	func sorted<Value: Comparable>(
		by keyPath: KeyPath<Element, Value>,
		_ comparator: (Value, Value) -> Bool = (<)
	) -> [Element] {
		sorted {
			comparator($0[keyPath: keyPath], $1[keyPath: keyPath])
		}
	}
}
