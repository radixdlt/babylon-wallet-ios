import AccountsClient
import ClientPrelude
import Cryptography
import EngineKit
import FactorSourcesClient
import Profile

// MARK: - ImportLegacyWalletClient + DependencyKey
extension ImportLegacyWalletClient: DependencyKey {
	public typealias Value = ImportLegacyWalletClient

	public static let liveValue: Self = {
		@Dependency(\.accountsClient) var accountsClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		@Sendable func migrate(
			accounts: NonEmpty<Set<OlympiaAccountToMigrate>>,
			factorSouceID: FactorSourceID.FromHash
		) async throws -> (accounts: NonEmpty<OrderedSet<MigratedAccount>>, networkID: NetworkID) {
			// we only allow import of olympia accounts into mainnet
			let networkID = NetworkID.mainnet
			let sortedOlympia = accounts.sorted(by: \.addressIndex)

			let accountIndexBase = await accountsClient.nextAccountIndex(networkID)

			var accountOffset: HD.Path.Component.Child.Value = 0
			guard let defaultAccountName: NonEmptyString = .init(rawValue: L10n.ImportOlympiaAccounts.AccountsToImport.unnamed) else {
				// The L10n string should not be empty, so this should not be possible
				struct ImplementationError: Error {}
				throw ImplementationError()
			}

			var accountsSet = OrderedSet<MigratedAccount>()
			for olympiaAccount in sortedOlympia {
				defer { accountOffset += 1 }
				let accountIndex = accountIndexBase + accountOffset
				let publicKey = SLIP10.PublicKey.ecdsaSecp256k1(olympiaAccount.publicKey)
				let factorInstance = HierarchicalDeterministicFactorInstance(
					id: factorSouceID,
					publicKey: publicKey,
					derivationPath: olympiaAccount.path.wrapAsDerivationPath()
				)

				let displayName = olympiaAccount.displayName ?? defaultAccountName

				let babylon = try Profile.Network.Account(
					networkID: networkID,
					index: HD.Path.Component.Child.Value(accountIndex),
					factorInstance: factorInstance,
					displayName: displayName,
					extraProperties: .init(appearanceID: .fromIndex(.init(accountIndex)))
				)

				let migrated = MigratedAccount(olympia: olympiaAccount, babylon: babylon)
				accountsSet.append(migrated)
			}

			guard let accounts = NonEmpty<OrderedSet<MigratedAccount>>(rawValue: accountsSet) else {
				throw NoValidatedAccountsError()
			}

			// Save all accounts
			try await accountsClient.saveVirtualAccounts(accounts.map(\.babylon))

			return (accounts: accounts, networkID: networkID)
		}

		return Self(
			shouldShowImportWalletShortcutInSettings: {
				@Dependency(\.userDefaultsClient) var userDefaultsClient

				let shouldHide = userDefaultsClient.hideMigrateOlympiaButton
				guard !shouldHide else {
					return false
				}

				do {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					if accounts.contains(where: \.isOlympiaAccount) {
						await userDefaultsClient.setHideMigrateOlympiaButton(true)
						return false
					}
				} catch {
					loggerGlobal.warning("Failed to load accounts, error: \(error)")
				}

				return await factorSourcesClient.getCurrentNetworkID() == .mainnet
			},
			parseHeaderFromQRCode: {
				let header = try CAP33.deserializeHeader(payload: $0)
				loggerGlobal.notice("Scanned Olympia QR found header: \(header)")
				return header
			},
			parseLegacyWalletFromQRCodes: {
				let parsed = try CAP33.deserialize(payloads: $0)
				let accountsArray = try parsed.accounts.rawValue.map(convert)
				guard
					!accountsArray.isEmpty,
					case let accountsSet = OrderedSet<OlympiaAccountToMigrate>(accountsArray),
					let nonEmpty = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(rawValue: accountsSet)
				else {
					struct FailedToConvertedParsedAccount: Swift.Error {}
					throw FailedToConvertedParsedAccount()
				}
				return .init(
					mnemonicWordCount: parsed.mnemonicWordCount,
					accounts: nonEmpty
				)
			},
			migrateOlympiaSoftwareAccountsToBabylon: { request in

				let olympiaFactorSource = request.olympiaFactorSource
				let factorSource = olympiaFactorSource?.factorSource

				guard let olympiaAccounts = NonEmpty<Set>(request.olympiaAccounts) else {
					throw NoValidatedAccountsError()
				}

				let (accounts, networkID) = try await migrate(
					accounts: olympiaAccounts,
					factorSouceID: request.olympiaFactorSouceID
				)

				let migratedAccounts = try MigratedSoftwareAccounts(
					networkID: networkID,
					accounts: accounts,
					factorSourceToSave: factorSource
				)

				return migratedAccounts
			},
			migrateOlympiaHardwareAccountsToBabylon: { request in
				let (accounts, networkID) = try await migrate(
					accounts: request.olympiaAccounts,
					factorSouceID: request.ledgerFactorSourceID
				)

				let migratedAccounts = try MigratedHardwareAccounts(
					networkID: networkID,
					ledgerID: request.ledgerFactorSourceID,
					accounts: accounts
				)

				return migratedAccounts
			},
			findAlreadyImportedIfAny: { scannedAccounts in
				do {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					let babylonAddresses = Set<AccountAddress>(accounts.map(\.address))
					let setOfExistingData = try Set(babylonAddresses.map {
						// the first byte is an address type discriminator byte, which differs between Babylon and Olympia,
						// so we must remove it.
						try Data(EngineToolkit.Address(address: $0.address).bytes().dropFirst())
					})
					guard let payloadByteCount = setOfExistingData.first?.count else {
						return []
					}
					var alreadyImported = Set<OlympiaAccountToMigrate.ID>()
					for scannedAccount in scannedAccounts {
						let hash = try Blake2b.hash(data: scannedAccount.publicKey.compressedRepresentation)
						let data = Data(hash.suffix(payloadByteCount))
						if setOfExistingData.contains(data) {
							alreadyImported.insert(scannedAccount.id)
						}
					}
					return alreadyImported
				} catch {
					loggerGlobal.error("Failed to find existing accounts, error: \(error)")
					return []
				}
			}
		)
	}()

	struct NoValidatedAccountsError: Error {}
}

func convert(
	parsedOlympiaAccount raw: Olympia.Parsed.Account
) throws -> OlympiaAccountToMigrate {
	let bech32Address = try deriveOlympiaAccountAddressFromPublicKey(publicKey: raw.publicKey.intoEngine(), olympiaNetwork: .mainnet).asStr()

	guard let nonEmptyString = NonEmptyString(rawValue: bech32Address) else {
		struct FailedToCreateNonEmptyOlympiaAddress: Swift.Error {}
		throw FailedToCreateNonEmptyOlympiaAddress()
	}
	let address = LegacyOlympiaAccountAddress(address: nonEmptyString)
	let derivationPath = try LegacyOlympiaBIP44LikeDerivationPath(
		index: raw.addressIndex
	)

	return .init(
		accountType: raw.accountType,
		publicKey: raw.publicKey,
		path: derivationPath,
		address: address,
		displayName: raw.displayName
	)
}
