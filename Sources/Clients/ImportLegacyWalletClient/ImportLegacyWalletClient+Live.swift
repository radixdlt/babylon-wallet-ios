import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import Profile

// MARK: - ImportLegacyWalletClient + DependencyKey
extension ImportLegacyWalletClient: DependencyKey {
	public typealias Value = ImportLegacyWalletClient

	public static let liveValue: Self = {
		@Dependency(\.accountsClient) var accountsClient

		@Sendable func migrate(
			accounts: Set<OlympiaAccountToMigrate>,
			factorSouceID: FactorSourceID
		) async throws -> (accounts: NonEmpty<OrderedSet<MigratedAccount>>, networkID: NetworkID) {
			let sortedOlympia = accounts.sorted(by: \.addressIndex)
			let networkID = Radix.Gateway.default.network.id // we import to the default network, not the current.
			let accountIndexOffset = try await accountsClient.getAccountsOnCurrentNetwork().count

			var accountsSet = OrderedSet<MigratedAccount>()
			for olympiaAccount in sortedOlympia {
				let publicKey = SLIP10.PublicKey.ecdsaSecp256k1(olympiaAccount.publicKey)
				let factorInstance = try HierarchicalDeterministicFactorInstance(
					factorSourceID: factorSouceID,
					publicKey: publicKey,
					derivationPath: olympiaAccount.path.wrapAsDerivationPath()
				)
				let displayName = olympiaAccount.displayName ?? "Unnamned olympia account \(olympiaAccount.addressIndex)"
				let accountIndex = accountIndexOffset + Int(olympiaAccount.addressIndex)

				let babylon = try Profile.Network.Account(
					networkID: networkID,
					factorInstance: factorInstance,
					displayName: displayName,
					extraProperties: .init(appearanceID: .fromIndex(accountIndex))
				)

				let migrated = MigratedAccount(olympia: olympiaAccount, babylon: babylon)
				accountsSet.append(migrated)
			}

			let accounts = NonEmpty<OrderedSet<MigratedAccount>>(rawValue: accountsSet)!

			// Save all accounts
			for account in accounts {
				try await accountsClient.saveVirtualAccount(.init(
					account: account.babylon,
					shouldUpdateFactorSourceNextDerivationIndex: false
				))
			}

			return (accounts: accounts, networkID: networkID)
		}

		return Self(
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

				let (accounts, networkID) = try await migrate(
					accounts: request.olympiaAccounts,
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
					accounts: accounts
				)

				return migratedAccounts
			},
			findAlreadyImportedIfAny: { scannedAccounts in
				@Dependency(\.engineToolkitClient) var engineToolkitClient
				do {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					let babylonAddresses = Set<AccountAddress>(accounts.map(\.address))
					let setOfExistingData = try Set(babylonAddresses.map {
						// the first byte is an address type discriminator byte, which differs between Babylon and Olympia,
						// so we must remove it.
						try Data(engineToolkitClient.decodeAddress($0.address).data.dropFirst())
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
}

func convert(
	parsedOlympiaAccount raw: Olympia.Parsed.Account
) throws -> OlympiaAccountToMigrate {
	@Dependency(\.engineToolkitClient) var engineToolkitClient

	let bech32Address = try engineToolkitClient.deriveOlympiaAdressFromPublicKey(raw.publicKey)

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
