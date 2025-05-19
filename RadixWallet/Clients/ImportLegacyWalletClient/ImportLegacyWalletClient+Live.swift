// MARK: - ImportLegacyWalletClient + DependencyKey
extension ImportLegacyWalletClient: DependencyKey {
	typealias Value = ImportLegacyWalletClient

	static let liveValue: Self = {
		@Dependency(\.accountsClient) var accountsClient

		/// NB: This migrates, but does not save the migrated accounts to the profile. That needs to be done separately,
		/// by calling `accountsClient.saveVirtualAccounts`
		@Sendable func migrate(
			accounts: NonEmpty<Set<OlympiaAccountToMigrate>>,
			factorSouceID: FactorSourceIDFromHash
		) async throws -> (accounts: NonEmpty<OrderedSet<MigratedAccount>>, networkID: NetworkID) {
			// we only allow import of olympia accounts into mainnet
			let networkID = NetworkID.mainnet
			let sortedOlympia = accounts.sorted(by: \.addressIndex)

			var accountOffset = 0
			guard let defaultAccountName: NonEmptyString = .init(rawValue: L10n.ImportOlympiaAccounts.AccountsToImport.unnamed) else {
				// The L10n string should not be empty, so this should not be possible
				struct ImplementationError: Error {}
				throw ImplementationError()
			}

			var accountsSet = OrderedSet<MigratedAccount>()
			for olympiaAccount in sortedOlympia {
				defer { accountOffset += 1 }
				let publicKey = Sargon.PublicKey.secp256k1(olympiaAccount.publicKey)

				let factorInstance = HierarchicalDeterministicFactorInstance(
					factorSourceId: factorSouceID,
					publicKey: .init(
						publicKey: publicKey,
						derivationPath: .bip44Like(
							value: olympiaAccount.path
						)
					)
				)

				let displayName = olympiaAccount.displayName ?? defaultAccountName

				let appearanceID = await accountsClient.nextAppearanceID(networkID, accountOffset)

				let babylon = Account(
					networkID: networkID,
					factorInstance: factorInstance,
					displayName: DisplayName(nonEmpty: displayName),
					extraProperties: .init(appearanceID: appearanceID)
				)

				let migrated = MigratedAccount(olympia: olympiaAccount, babylon: babylon)
				accountsSet.append(migrated)
			}

			guard let accounts = NonEmpty<OrderedSet<MigratedAccount>>(rawValue: accountsSet) else {
				throw NoValidatedAccountsError()
			}

			return (accounts: accounts, networkID: networkID)
		}

		return Self(
			shouldShowImportWalletShortcutInSettings: {
				@Dependency(\.userDefaults) var userDefaults

				let shouldHide = userDefaults.hideMigrateOlympiaButton
				guard !shouldHide else {
					return false
				}

				do {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					if accounts.contains(where: \.isLegacy) {
						userDefaults.setHideMigrateOlympiaButton(true)
						return false
					}
				} catch {
					loggerGlobal.warning("Failed to load accounts, error: \(error)")
				}

				return await accountsClient.getCurrentNetworkID() == .mainnet
			},
			parseHeaderFromQRCode: {
				let header = try CAP33.deserializeHeader(payload: $0)
				loggerGlobal.notice("Scanned Olympia QR found header: \(header)")
				return header
			},
			parseLegacyWalletFromQRCodes: {
				let parsed = try CAP33.deserialize(payloads: $0)
				let accountsArray = parsed.accounts.rawValue.map(convert)
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

					var alreadyImported = Set<OlympiaAccountToMigrate.ID>()
					for scannedAccount in scannedAccounts {
						if babylonAddresses.contains(where: { babylon in
							babylon.wasMigratedFromLegacyOlympia(address: scannedAccount.address)
						}) {
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
	parsedOlympiaAccount raw: Olympia.Parsed.ParsedAccount
) -> OlympiaAccountToMigrate {
	let address = LegacyOlympiaAccountAddress(
		publicKey: raw.publicKey
	)

	let derivationPath = BIP44LikePath(
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
