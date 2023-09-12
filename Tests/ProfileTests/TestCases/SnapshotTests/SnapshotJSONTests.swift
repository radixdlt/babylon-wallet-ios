@testable import Profile
import TestingPrelude

extension MnemonicWithPassphrase {
	func deviceFactorSourceID() throws -> FactorSource.ID.FromHash {
		try FactorSource.ID.FromHash(
			kind: .device,
			mnemonicWithPassphrase: self
		)
	}
}

// MARK: - SnapshotTestVector
public struct SnapshotTestVector: Codable, Equatable {
	public struct IdentifiableMnemonic: Codable, Equatable {
		public let factorSourceID: FactorSourceID
		public let mnemonicWithPassphrase: MnemonicWithPassphrase

		public init(
			mnemonicWithPassphrase: MnemonicWithPassphrase
		) throws {
			self.factorSourceID = try mnemonicWithPassphrase.deviceFactorSourceID().embed()
			self.mnemonicWithPassphrase = mnemonicWithPassphrase
		}
	}

	public struct EncryptedSnapshotWithPassword: Codable, Equatable {
		public let password: String
		public let snapshot: EncryptedProfileSnapshot
		func decrypted() throws -> ProfileSnapshot {
			try snapshot.decrypt(password: password)
		}
	}

	public let snapshotVersion: ProfileSnapshot.Header.Version
	public let mnemonics: [IdentifiableMnemonic]
	public let encryptedSnapshots: [EncryptedSnapshotWithPassword]
	public let plaintext: ProfileSnapshot

	public init(
		mnemonics: [IdentifiableMnemonic],
		encryptedSnapshots: [EncryptedSnapshotWithPassword],
		plaintext: ProfileSnapshot
	) throws {
		let decryptions = try encryptedSnapshots.map { try $0.decrypted() }
		guard decryptions.allSatisfy({ $0 == plaintext }) else {
			struct EncryptedSnapshotDoesNotEqualPlaintext: Error {}
			throw EncryptedSnapshotDoesNotEqualPlaintext()
		}
		guard
			Set(plaintext.factorSources.filter { $0.kind == .device }.map(\.id)) == Set(mnemonics.map(\.factorSourceID))
		else {
			struct MissingMnemonic: Error {}
			throw MissingMnemonic()
		}
		self.snapshotVersion = plaintext.header.snapshotVersion
		self.mnemonics = mnemonics
		self.encryptedSnapshots = encryptedSnapshots
		self.plaintext = plaintext
	}

	public static func encrypting(
		plaintext: ProfileSnapshot,
		mnemonics: [IdentifiableMnemonic],
		passwords: [String]
	) throws -> Self {
		let kdfScheme = PasswordBasedKeyDerivationScheme.default
		let encryptionScheme = EncryptionScheme.default
		let encryptions = try passwords.map { password in
			let encryption = try plaintext.encrypt(
				password: password,
				kdfScheme: kdfScheme,
				encryptionScheme: encryptionScheme
			)
			return EncryptedSnapshotWithPassword(
				password: password,
				snapshot: encryption
			)
		}
		return try .init(
			mnemonics: mnemonics,
			encryptedSnapshots: encryptions,
			plaintext: plaintext
		)
	}
}

// MARK: - SnapshotJSONTests
final class SnapshotJSONTests: TestCase {
	func test_generate() throws {
		let jsonDecoder = JSONDecoder()
		let plaintextSnapshot = try jsonDecoder.decode(ProfileSnapshot.self, from: plaintext.data(using: .utf8)!)

		let vector = try SnapshotTestVector.encrypting(
			plaintext: plaintextSnapshot,
			mnemonics: mnemomics.map {
				try SnapshotTestVector.IdentifiableMnemonic(
					mnemonicWithPassphrase: $0
				)
			}, passwords: [
				"",
				"Radix... just imagine!", // ref: https://github.com/radixdlt/radixdlt-swift-archive/blob/c289fa5bb8996fc427d2df064d9ae433665cac88/Tests/TestCases/UnitTests/RadixStack/3_Chemistry/AtomToExecutedActionMapper/DefaultAtomToTransactionMapperCreateTokenFromGenesisAtomTests.swift#L55
				"open sesame",
				"babylon",
			]
		)
	}
}

private let mnemomics: [MnemonicWithPassphrase] = try! [
	.init(
		mnemonic: .init(
			phrase: "alley urge tag valid execute hat little funny armed salute orient hurt balcony urban found clip tennis wrong turtle canoe castle exist pledge test",
			language: .english
		)
	),
	.init(
		mnemonic: .init(
			phrase: "gentle hawk winner rain embrace erosion call update photo frost fatal wrestle",
			language: .english
		)
	),
	.init(
		mnemonic: .init(
			phrase: "smile entry satisfy shed margin rubber disorder hungry foot error ribbon cradle aim round october blind lab spend",
			language: .english
		)
	)
]

private let plaintext = """
{"appPreferences":{"display":{"ledgerHQHardwareWalletSigningDisplayMode":"summary","fiatCurrencyPriceTarget":"usd","isCurrencyAmountVisible":true},"security":{"isCloudProfileSyncEnabled":true,"structureConfigurationReferences":[],"isDeveloperModeEnabled":true},"p2pLinks":[{"displayName":"Scratched 24","connectionPassword":"b8c3a14c9b23c93da9f8b73edff6b85a640be5adacd1538648a30dfb6461d4fe"}],"gateways":{"current":"https://rcnet-v3.radixdlt.com/","saved":[{"network":{"name":"zabanet","id":14,"displayDescription":"RCnet-V3 test network"},"url":"https://rcnet-v3.radixdlt.com/"},{"network":{"name":"stokenet","id":2,"displayDescription":"Stokenet"},"url":"https://babylon-stokenet-gateway.radixdlt.com"}]},"transaction":{"defaultDepositGuarantee":"0.975"}},"networks":[{"networkID":14,"personas":[{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"3c9f6a080e75c28e9210bf53fee777e3f943852790b2c016dc699e46d041477e"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/618H/1460H/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":0},"discriminator":"unsecured"},"networkID":14,"displayName":"Sajjon","personaData":{"postalAddresses":[],"creditCards":[],"emailAddresses":[{"id":"8D8AB282-AB20-4D07-8461-06A31553AF1C","value":"alex@cyon.com"}],"name":{"id":"D264960B-1E2B-4E40-AD50-D281B9DBB6D1","value":{"nickname":"Alex","familyName":"Alexander ","variant":"western","givenNames":"Cyon"}},"phoneNumbers":[{"id":"F30A2A14-E25F-4597-8A49-E74FEDB10F44","value":"087657004"}],"urls":[]},"address":"identity_tdx_e_122k9saakdjazzwm98rlpjlwewy0wvx0csmtvstdut528r0t0z8cy30"}],"accounts":[{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"3feb8194ead2e526fbcc4c1673a7a8b29d8cee0b32bb9393692f739821dd256b"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/525H/1460H/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":0},"discriminator":"unsecured"},"networkID":14,"appearanceID":0,"displayName":"Zaba 0","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_128vkt2fur65p4hqhulfv3h0cknrppwtjsstlttkfamj4jnnpm82gsw"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"3c04690f4ad8890bfdf5a62bac2843b8ee79ab335c9bf4ed1e786ff676709413"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/525H/1460H/1H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":1},"discriminator":"unsecured"},"networkID":14,"appearanceID":1,"displayName":"Zaba 1","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_129fj4fqmz2ldej5lg2hx9laty9s6464snr6ly0243p32jmd757yke7"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"fe6368cf2907d0da61a68c31e461213b8e56ba84f1cfbdb4d79311fce331b7ee"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/525H/1460H/2H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":2},"discriminator":"unsecured"},"networkID":14,"appearanceID":2,"displayName":"Zaba 2","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_129enl4x6w6mz6nlh9y4hszx6zwfvv3q80keqdzqkewvltugp8g6g7v"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"02f669a43024d90fde69351ccc53022c2f86708d9b3c42693640733c5778235da5"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"8bfacfe888d4e3819c6e9528a1c8f680a4ba73e466d7af4ee204591093006589"},"discriminator":"fromHash"}},"entityIndex":3},"discriminator":"unsecured"},"networkID":14,"appearanceID":3,"displayName":"Olympia|Soft|0","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_169s2cfz044euhc4yjg4xe4pg55w97rq2c6jh50zsdcpuz5gk6cag6v"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"023a41f437972033fa83c3c4df08dc7d68212ccac07396a29aca971ad5ba3c27c8"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/1H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"8bfacfe888d4e3819c6e9528a1c8f680a4ba73e466d7af4ee204591093006589"},"discriminator":"fromHash"}},"entityIndex":4},"discriminator":"unsecured"},"networkID":14,"appearanceID":4,"displayName":"Olympia|Soft|1","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16x88ghu9hd3hz4c9gumqjafrcwqtzk67wmpds7xg6uaz0kf42v5hju"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"0233dc38ad9e8fca2653563199e793ee8d8a1a5071d1fc2996a6c51c9b86b36d8a"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/1H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"eda055ed256d156f62013da6cf5fb6104339b5c8666dd3f5512030950b1e3a29"},"discriminator":"fromHash"}},"entityIndex":5},"discriminator":"unsecured"},"networkID":14,"appearanceID":5,"displayName":"S18 | Sajjon | 1","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16yszyl5pd54vdqm4wyazdgtr7j3d5cl33gew3mzy6r9443am5dlsr7"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"035e86fc1679aefcb186a3c758503aa146e2a4e730e84daf6fd735861ccd5d8978"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/3H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"eda055ed256d156f62013da6cf5fb6104339b5c8666dd3f5512030950b1e3a29"},"discriminator":"fromHash"}},"entityIndex":6},"discriminator":"unsecured"},"networkID":14,"appearanceID":6,"displayName":"S18 | Sajjon | 3","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16ysdhjfehs8t80u4ew3w3f8yygkx7v3h3erptrzjacv86sn9l3feln"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"03f43fba6541031ef2195f5ba96677354d28147e45b40cde4662bec9162c361f55"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0"},"discriminator":"fromHash"}},"entityIndex":7},"discriminator":"unsecured"},"networkID":14,"appearanceID":7,"displayName":"0|RDX|Dev Nano S|Some very lon","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16x5wz8wmkumuhn49klq0zwgjn9d8xs7n95maxam04vawld2drf2dkj"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"0206ea8842365421f48ab84e6b1b197010e5a43a527952b11bc6efe772965e97cc"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/1H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0"},"discriminator":"fromHash"}},"entityIndex":8},"discriminator":"unsecured"},"networkID":14,"appearanceID":8,"displayName":"1|RDX|Dev Nano S|Forbidden ___","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16y6q3q6ey64j5qvkex3q0yshtln6z2lmyk254xrjcq393rc070x66z"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"0220e2ef980a86888800573b0f5a30492549c88c1808821475c828aeccdca4cc5a"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"9e2e0a2b4b96e8729f5553ffa8865eaac10088569ef8bcd7b3fa61b89fde1764"},"discriminator":"fromHash"}},"entityIndex":9},"discriminator":"unsecured"},"networkID":14,"appearanceID":9,"displayName":"Shadow 25 | 0","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_16yyhtwlwrtpdqe2jufg2xw2289j4dtnk542dm69m7h89l4x5xm60k7"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"secp256k1","compressedData":"034a8a2ee1801d91cf8c9157d8694ae0d8d2c9563021a9764a34580493f75d0c75"},"derivationPath":{"scheme":"bip44Olympia","path":"m/44H/1022H/0H/0/1H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"9e2e0a2b4b96e8729f5553ffa8865eaac10088569ef8bcd7b3fa61b89fde1764"},"discriminator":"fromHash"}},"entityIndex":10},"discriminator":"unsecured"},"networkID":14,"appearanceID":10,"displayName":"Shadow 25 | 1","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_169cdlneks2wrrmg82cc36xqtx2ng8qjtkpe0j3sfzddl0xje47janr"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"d24228459e0000d91b7256cac6fd8f9b0cb30dfef209db201912fb0b8d710edb"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/525H/1460H/11H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0"},"discriminator":"fromHash"}},"entityIndex":11},"discriminator":"unsecured"},"networkID":14,"appearanceID":11,"displayName":"Babylon Ledger 24","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_12yavnpctf6l2dw76tazge90kkufzks45vq6u28vvarse6cyra5stuv"},{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"7d918320fdd9d4102f2392aec4a6c43e959645cb525b4bd407cbc9c5bac00495"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/14H/525H/1460H/12H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"ledgerHQHardwareWallet","body":"9e2e0a2b4b96e8729f5553ffa8865eaac10088569ef8bcd7b3fa61b89fde1764"},"discriminator":"fromHash"}},"entityIndex":12},"discriminator":"unsecured"},"networkID":14,"appearanceID":0,"displayName":"Babylon ledger 25","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_e_128duqx53e4e6hpz4vxkm9qskpqgu8un0p49gm2t8lfcsfxl9vej4eg"}],"authorizedDapps":[{"networkID":14,"dAppDefinitionAddress":"account_tdx_e_128uml7z6mqqqtm035t83alawc3jkvap9sxavecs35ud3ct20jxxuhl","displayName":"Gumball Club","referencesToAuthorizedPersonas":[{"sharedAccounts":{"request":{"quantifier":"atLeast","quantity":1},"ids":["account_tdx_e_128vkt2fur65p4hqhulfv3h0cknrppwtjsstlttkfamj4jnnpm82gsw","account_tdx_e_129fj4fqmz2ldej5lg2hx9laty9s6464snr6ly0243p32jmd757yke7","account_tdx_e_129enl4x6w6mz6nlh9y4hszx6zwfvv3q80keqdzqkewvltugp8g6g7v","account_tdx_e_169s2cfz044euhc4yjg4xe4pg55w97rq2c6jh50zsdcpuz5gk6cag6v","account_tdx_e_16x88ghu9hd3hz4c9gumqjafrcwqtzk67wmpds7xg6uaz0kf42v5hju","account_tdx_e_16yszyl5pd54vdqm4wyazdgtr7j3d5cl33gew3mzy6r9443am5dlsr7","account_tdx_e_16ysdhjfehs8t80u4ew3w3f8yygkx7v3h3erptrzjacv86sn9l3feln","account_tdx_e_16x5wz8wmkumuhn49klq0zwgjn9d8xs7n95maxam04vawld2drf2dkj","account_tdx_e_16y6q3q6ey64j5qvkex3q0yshtln6z2lmyk254xrjcq393rc070x66z","account_tdx_e_16yyhtwlwrtpdqe2jufg2xw2289j4dtnk542dm69m7h89l4x5xm60k7","account_tdx_e_169cdlneks2wrrmg82cc36xqtx2ng8qjtkpe0j3sfzddl0xje47janr","account_tdx_e_12yavnpctf6l2dw76tazge90kkufzks45vq6u28vvarse6cyra5stuv","account_tdx_e_128duqx53e4e6hpz4vxkm9qskpqgu8un0p49gm2t8lfcsfxl9vej4eg"]},"identityAddress":"identity_tdx_e_122k9saakdjazzwm98rlpjlwewy0wvx0csmtvstdut528r0t0z8cy30","sharedPersonaData":{},"lastLogin":"2023-09-11T16:55:33Z"}]},{"networkID":14,"dAppDefinitionAddress":"account_tdx_e_168ydk240yx69yl7zdz2mzkdjc3r5p6n4gwypqsype2d6d942m5z2ns","displayName":"Radix Sandbox dApp","referencesToAuthorizedPersonas":[{"sharedAccounts":{"request":{"quantifier":"atLeast","quantity":1},"ids":["account_tdx_e_128vkt2fur65p4hqhulfv3h0cknrppwtjsstlttkfamj4jnnpm82gsw","account_tdx_e_129fj4fqmz2ldej5lg2hx9laty9s6464snr6ly0243p32jmd757yke7","account_tdx_e_129enl4x6w6mz6nlh9y4hszx6zwfvv3q80keqdzqkewvltugp8g6g7v","account_tdx_e_169s2cfz044euhc4yjg4xe4pg55w97rq2c6jh50zsdcpuz5gk6cag6v","account_tdx_e_16x88ghu9hd3hz4c9gumqjafrcwqtzk67wmpds7xg6uaz0kf42v5hju","account_tdx_e_16yszyl5pd54vdqm4wyazdgtr7j3d5cl33gew3mzy6r9443am5dlsr7","account_tdx_e_16ysdhjfehs8t80u4ew3w3f8yygkx7v3h3erptrzjacv86sn9l3feln","account_tdx_e_16x5wz8wmkumuhn49klq0zwgjn9d8xs7n95maxam04vawld2drf2dkj","account_tdx_e_16y6q3q6ey64j5qvkex3q0yshtln6z2lmyk254xrjcq393rc070x66z","account_tdx_e_16yyhtwlwrtpdqe2jufg2xw2289j4dtnk542dm69m7h89l4x5xm60k7","account_tdx_e_169cdlneks2wrrmg82cc36xqtx2ng8qjtkpe0j3sfzddl0xje47janr","account_tdx_e_12yavnpctf6l2dw76tazge90kkufzks45vq6u28vvarse6cyra5stuv","account_tdx_e_128duqx53e4e6hpz4vxkm9qskpqgu8un0p49gm2t8lfcsfxl9vej4eg"]},"identityAddress":"identity_tdx_e_122k9saakdjazzwm98rlpjlwewy0wvx0csmtvstdut528r0t0z8cy30","sharedPersonaData":{"name":"D264960B-1E2B-4E40-AD50-D281B9DBB6D1","emailAddresses":{"request":{"quantifier":"exactly","quantity":1},"ids":["8D8AB282-AB20-4D07-8461-06A31553AF1C"]},"phoneNumbers":{"request":{"quantifier":"exactly","quantity":1},"ids":["F30A2A14-E25F-4597-8A49-E74FEDB10F44"]}},"lastLogin":"2023-09-11T17:02:06Z"}]}]},{"networkID":2,"personas":[{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"679152f01032dc15895247a394d622d31342017951471922ba8170e0ee4fb90c"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/2H/618H/1460H/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":0},"discriminator":"unsecured"},"networkID":2,"displayName":"Stokeman","personaData":{"postalAddresses":[],"creditCards":[],"phoneNumbers":[],"emailAddresses":[],"urls":[]},"address":"identity_tdx_2_1224clayjwq45swgd0xj2uc4s3gq4l6g7q77f9d290su4flufq2lt9j"}],"accounts":[{"securityState":{"unsecuredEntityControl":{"transactionSigning":{"badge":{"virtualSource":{"hierarchicalDeterministicPublicKey":{"publicKey":{"curve":"curve25519","compressedData":"1145c0041719f2640333ebdfa6652b8399bd73f9205af8a94beb25f6375b5900"},"derivationPath":{"scheme":"cap26","path":"m/44H/1022H/2H/525H/1460H/0H"}},"discriminator":"hierarchicalDeterministicPublicKey"},"discriminator":"virtualSource"},"factorSourceID":{"fromHash":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"discriminator":"fromHash"}},"entityIndex":0},"discriminator":"unsecured"},"networkID":2,"appearanceID":0,"displayName":"Stokenet","onLedgerSettings":{"thirdPartyDeposits":{"depositRule":"acceptAll","assetsExceptionList":[],"depositorsAllowList":[]}},"address":"account_tdx_2_12ygsf87pma439ezvdyervjfq2nhqme6reau6kcxf6jtaysaxl7sqvd"}],"authorizedDapps":[]}],"header":{"contentHint":{"numberOfNetworks":2,"numberOfAccountsOnAllNetworksInTotal":14,"numberOfPersonasOnAllNetworksInTotal":2},"id":"E5E4477B-E47B-4B64-BBC8-F8F40E8BEB74","lastUsedOnDevice":{"id":"66F07CA2-A9D9-49E5-8152-77ACA3D1DD74","date":"2023-09-11T16:07:57Z","description":"iPhone (iPhone)"},"creatingDevice":{"id":"66F07CA2-A9D9-49E5-8152-77ACA3D1DD74","date":"2023-09-11T16:05:55Z","description":"iPhone (iPhone)"},"lastModified":"2023-09-11T17:02:38Z","snapshotVersion":49},"factorSources":[{"device":{"id":{"kind":"device","body":"c9e67a9028fb3150304c77992710c35c8e479d4fa59f7c45a96ce17f6fdf1d2c"},"common":{"flags":[],"addedOn":"2023-09-11T16:05:55Z","cryptoParameters":{"supportedCurves":["curve25519"],"supportedDerivationPathSchemes":["cap26"]},"lastUsedOn":"2023-09-11T16:55:59Z"},"hint":{"name":"iPhone","model":"iPhone","mnemonicWordCount":24}},"discriminator":"device"},{"device":{"id":{"kind":"device","body":"8bfacfe888d4e3819c6e9528a1c8f680a4ba73e466d7af4ee204591093006589"},"common":{"flags":[],"addedOn":"2023-09-11T16:23:40Z","cryptoParameters":{"supportedCurves":["curve25519","secp256k1"],"supportedDerivationPathSchemes":["cap26","bip44Olympia"]},"lastUsedOn":"2023-09-11T16:56:14Z"},"hint":{"name":"","model":"","mnemonicWordCount":12}},"discriminator":"device"},{"device":{"id":{"kind":"device","body":"eda055ed256d156f62013da6cf5fb6104339b5c8666dd3f5512030950b1e3a29"},"common":{"flags":[],"addedOn":"2023-09-11T16:26:44Z","cryptoParameters":{"supportedCurves":["curve25519","secp256k1"],"supportedDerivationPathSchemes":["cap26","bip44Olympia"]},"lastUsedOn":"2023-09-11T16:56:33Z"},"hint":{"name":"","model":"","mnemonicWordCount":18}},"discriminator":"device"},{"ledgerHQHardwareWallet":{"id":{"kind":"ledgerHQHardwareWallet","body":"41ac202687326a4fc6cb677e9fd92d08b91ce46c669950d58790d4d5e583adc0"},"common":{"flags":[],"addedOn":"2023-09-11T16:35:08Z","cryptoParameters":{"supportedCurves":["curve25519","secp256k1"],"supportedDerivationPathSchemes":["cap26","bip44Olympia"]},"lastUsedOn":"2023-09-11T16:57:33Z"},"hint":{"name":"Scratched 24","model":"nanoS"}},"discriminator":"ledgerHQHardwareWallet"},{"ledgerHQHardwareWallet":{"id":{"kind":"ledgerHQHardwareWallet","body":"9e2e0a2b4b96e8729f5553ffa8865eaac10088569ef8bcd7b3fa61b89fde1764"},"common":{"flags":[],"addedOn":"2023-09-11T16:38:12Z","cryptoParameters":{"supportedCurves":["curve25519","secp256k1"],"supportedDerivationPathSchemes":["cap26","bip44Olympia"]},"lastUsedOn":"2023-09-11T16:59:10Z"},"hint":{"name":"Orange 25","model":"nanoS+"}},"discriminator":"ledgerHQHardwareWallet"}]}
"""
