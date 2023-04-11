import ClientPrelude
import Cryptography
import Profile

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
		let header = Olympia.Export.Payload.Header(payloadCount: numberOfPayLoads, payloadIndex: 0, mnemonicWordCount: mnemonic.wordCount.wordCount)

		return Self(
			parseHeaderFromQRCode: { _ in
				header
			},
			parseLegacyWalletFromQRCodes: { _ in

				let accounts: [OlympiaAccountToMigrate] = try (0 ..< numberOfAccounts).map {
					let addressIndex = UInt32($0)
					let path = try LegacyOlympiaBIP44LikeDerivationPath(index: addressIndex)
					let publicKey = try hdRoot.derivePrivateKey(path: path.fullPath, curve: K1.self).publicKey
					let accountType = ($0 % 2 == 0) ? Olympia.AccountType.software : Olympia.AccountType.hardware

					let name = "Olympia \(passphrase) \(String(describing: accountType)) i=\($0)"

					let parsedOlympiaAccount = Olympia.Parsed.Account(
						accountType: accountType,
						publicKey: publicKey,
						displayName: .init(rawValue: name),
						addressIndex: addressIndex
					)

					let accountChecked = try convert(
						parsedOlympiaAccount: parsedOlympiaAccount
					)

					assert(accountChecked.path == path)
					assert(accountChecked.publicKey.compressedRepresentation == publicKey.compressedRepresentation)
					return accountChecked
				}
				guard let nonEmpty = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(rawValue: .init(uncheckedUniqueElements: accounts)) else {
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

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}
