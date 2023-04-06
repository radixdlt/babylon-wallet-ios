import ClientPrelude
import Cryptography

extension DependencyValues {
	public var importLegacyWalletClient: ImportLegacyWalletClient {
		get { self[ImportLegacyWalletClient.self] }
		set { self[ImportLegacyWalletClient.self] = newValue }
	}
}

// MARK: - ImportLegacyWalletClient + TestDependencyKey
extension ImportLegacyWalletClient: TestDependencyKey {
	public static let previewValue: Self = {
		let numberOfPayLoads = 2
		let accountsPerPayload = 20
		let numberOfAccounts = numberOfPayLoads * accountsPerPayload
		let mnemonic = try! Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let passphrase = try! Mnemonic().words[0].capitalized

		print("✅ Passhprase: \(passphrase)")

		let hdRoot = try! mnemonic.hdRoot(passphrase: passphrase)
		let header = OlympiaExportHeader(payloadCount: numberOfPayLoads, mnemonicWordCount: mnemonic.wordCount.rawValue)
		return Self(
			parseHeaderFromQRCode: { _ in
				header
			},
			parseLegacyWalletFromQRCodes: { _ in
				let accounts: [AccountNonChecked] = try (0 ..< numberOfAccounts).map {
					let path = try LegacyOlympiaBIP44LikeDerivationPath(index: UInt32($0))
					let publicKey = try hdRoot.derivePublicKey(path: path.wrapAsDerivationPath(), curve: .secp256k1)
					let accountType = ($0 % 2 == 0) ? LegacyOlypiaAccountType.software.rawValue : LegacyOlypiaAccountType.hardware.rawValue
					let accountNonChecked = AccountNonChecked(
						accountType: accountType,
						pk: publicKey.compressedData.hex,
						path: path.derivationPath,
						name: "Olympia \(passphrase) \(String(describing: accountType)) i=\($0)"
					)

					let accountChecked = try accountNonChecked.checked()
					assert(accountChecked.path == path)
					assert(accountChecked.publicKey.compressedRepresentation == publicKey.compressedRepresentation)
					return accountNonChecked
				}
				let accountSet = try OrderedSet(uncheckedUniqueElements: accounts.map { try $0.checked() })
				guard let nonEmpty = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(rawValue: accountSet) else {
					throw ImportedOlympiaWalletFailedToFindAnyAccounts()
				}
				return ScannedParsedOlympiaWalletToMigrate(
					mnemonicWordCount: mnemonic.wordCount,
					accounts: nonEmpty
				)
			},
			migrateOlympiaSoftwareAccountsToBabylon: { _ in throw NoopError() },
			migrateOlympiaHardwareAccountsToBabylon: { _ in throw NoopError() }
		)
	}()

	public static let testValue = Self(
		parseHeaderFromQRCode: unimplemented("\(Self.self).parseHeaderFromQRCode"),
		parseLegacyWalletFromQRCodes: unimplemented("\(Self.self).parseLegacyWalletFromQRCodes"),
		migrateOlympiaSoftwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaSoftwareAccountsToBabylon"),
		migrateOlympiaHardwareAccountsToBabylon: unimplemented("\(Self.self).migrateOlympiaHardwareAccountsToBabylon")
	)
}
