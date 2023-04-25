import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

// MARK: - BIP44Tests
final class BIP44Tests: TestCase {
	struct BIP44TestSuite: Codable, Equatable {
		let testGroups: [TestGroup]
		let description: String
		struct TestGroup: Codable, Equatable {
			let mnemonic: String
			let tests: [Test]

			struct Test: Codable, Equatable {
				let path: String
				let isStrictBIP44: Bool
				let privateKey: String
				let publicKeyCompressed: String
			}
		}
	}

	func test_bip44_generate() throws {
		let ledgerMnemonic = try Mnemonic(phrase: "equip will roof matter pink blind book anxiety banner elbow sun young", language: .english)

		var mnemonics = [ledgerMnemonic]
		for wordCount in BIP39.WordCount.allCases {
			try mnemonics.append(Mnemonic.generate(wordCount: wordCount))
		}

		let groups = try mnemonics.map { mnemonic -> BIP44TestSuite.TestGroup in
			let hdRoot = try mnemonic.hdRoot()
			let tests = try [true, false].flatMap { shouldHardenLastPathComponent -> [BIP44TestSuite.TestGroup.Test] in
				try (0 ..< 10).map { addressIndex -> BIP44TestSuite.TestGroup.Test in
					let path = try LegacyOlympiaBIP44LikeDerivationPath(
						index: .init(addressIndex),
						shouldHardenLastPathComponent: shouldHardenLastPathComponent
					)
					let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: SECP256K1.self)
					let privateKey = try XCTUnwrap(keyPair.privateKey)
					let publicKey = keyPair.publicKey

					return BIP44TestSuite.TestGroup.Test(
						path: path.derivationPath,
						isStrictBIP44: !shouldHardenLastPathComponent,
						privateKey: privateKey.rawRepresentation.hex,
						publicKeyCompressed: publicKey.compressedRepresentation.hex
					)
				}
			}
			return BIP44TestSuite.TestGroup(mnemonic: mnemonic.phrase, tests: tests)
		}

		let suite = BIP44TestSuite(testGroups: groups, description: "Secp256k1 BIP44 and BIP44 like tests")
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
		let data = try jsonEncoder.encode(suite)
		print(String(data: data, encoding: .utf8)!)
	}

	func test_bip44_vectors() throws {
		try testFixture(
			bundle: .module,
			jsonName: "bip44_secp256k1"
		) { (testSuite: BIP44TestSuite) in
			try testSuite.testGroups.forEach(doTestGroup)
		}
	}
}

extension BIP44Tests {
	private func doTestGroup(_ testGroup: BIP44TestSuite.TestGroup) throws {
		let mnemonic = try Mnemonic(phrase: testGroup.mnemonic, language: .english)
		let hdRoot = try mnemonic.hdRoot()
		for test in testGroup.tests {
			let path = try LegacyOlympiaBIP44LikeDerivationPath(path: .init(string: test.path))
			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: SECP256K1.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = keyPair.publicKey
			XCTAssertEqual(privateKey.rawRepresentation.hex, test.privateKey)
			XCTAssertEqual(publicKey.compressedRepresentation.hex, test.publicKeyCompressed)
		}
	}
}
