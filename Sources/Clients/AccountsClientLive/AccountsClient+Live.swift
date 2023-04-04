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
			checkIfNeedsAccountRecovery: { account in
				@Dependency(\.secureStorageClient) var secureStorageClient
				do {
					switch account.securityState {
					case let .unsecured(unsecuredEntityControl):
						let factorInstance = unsecuredEntityControl.genesisFactorInstance
						let factorSourceID = factorInstance.factorSourceID
						let mnemonic = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .debugOnlyInspect)
						return mnemonic == nil
					}

				} catch {
					loggerGlobal.warning("Failed to load mnemonic or derive publickey: \(error)")
					return true // We consider this as 'needs account recovery'
				}
			}
		)
	}

	public static let liveValue: Self = .live()
}
