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
			parseHeaderFromQRCode: { try Self.previewValue.parseHeaderFromQRCode($0) },
			parseLegacyWalletFromQRCodes: { try Self.previewValue.parseLegacyWalletFromQRCodes($0) },
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

func convertUncheckedAccount(
	_ raw: AccountNonChecked,
	engineToolkitClient: EngineToolkitClient
) throws -> OlympiaAccountToMigrate {
	let publicKeyData = try Data(hex: raw.pk)
	let publicKey = try K1.PublicKey(compressedRepresentation: publicKeyData)

	let bech32Address = try engineToolkitClient.deriveOlympiaAdressFromPublicKey(publicKey)

	guard let nonEmptyString = NonEmptyString(rawValue: bech32Address) else {
		fatalError()
	}
	let address = LegacyOlympiaAccountAddress(address: nonEmptyString)

	guard let accountType = LegacyOlympiaAccountType(rawValue: raw.accountType) else {
		fatalError()
	}

	return try .init(
		accountType: accountType,
		publicKey: .init(compressedRepresentation: publicKeyData),
		path: .init(derivationPath: raw.path),
		address: address,
		displayName: raw.name.map { NonEmptyString(rawValue: $0) } ?? nil
	)
}
