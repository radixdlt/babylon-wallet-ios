import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient
import Profile

// MARK: - ImportLegacyWalletClient + DependencyKey
extension ImportLegacyWalletClient: DependencyKey {
	public typealias Value = ImportLegacyWalletClient

	public static let liveValue: Self = {
		@Sendable func migrate(
			accounts: Set<OlympiaAccountToMigrate>,
			factorSouceID: FactorSourceID
		) async throws -> (accounts: NonEmpty<OrderedSet<MigratedAccount>>, networkID: NetworkID) {
			@Dependency(\.accountsClient) var accountsClient

			let sortedOlympia = accounts.sorted(by: \.addressIndex)
			let networkID = Radix.Gateway.default.network.id // we import to the default network, not the current.
			let accountIndexOffset = try await accountsClient.getAccountsOnCurrentNetwork().count

			var accountsSet = OrderedSet<MigratedAccount>()
			for olympiaAccount in sortedOlympia {
				let publicKey = SLIP10.PublicKey.ecdsaSecp256k1(olympiaAccount.publicKey)
				let address = try Profile.Network.Account.deriveAddress(networkID: networkID, publicKey: publicKey)
				let factorInstance = FactorInstance(
					factorSourceID: factorSouceID,
					publicKey: publicKey,
					derivationPath: olympiaAccount.path.wrapAsDerivationPath()
				)
				let accountIndex = accountIndexOffset + Int(olympiaAccount.addressIndex)

				let babylon = Profile.Network.Account(
					networkID: networkID,
					address: address,
					securityState: .unsecured(.init(genesisFactorInstance: factorInstance)),
					appearanceID: .fromIndex(accountIndex),
					displayName: olympiaAccount.displayName ?? "Unnamned olympia account \(olympiaAccount.addressIndex)"
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
				try CAP33.deserializeHeader(payload: $0)
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
				let factorSource = olympiaFactorSource.hdOnDeviceFactorSource

				let (accounts, networkID) = try await migrate(
					accounts: request.olympiaAccounts,
					factorSouceID: factorSource.id
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
	let derivationPath = try LegacyOlympiaBIP44LikeDerivationPath(index: raw.addressIndex)

	return try .init(
		accountType: raw.accountType,
		publicKey: raw.publicKey,
		path: derivationPath,
		address: address,
		displayName: raw.displayName
	)
}
