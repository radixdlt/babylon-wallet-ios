@testable import Cryptography
import TestingPrelude

final class SerializeTests: XCTestCase {
	/// Expected values generated with Python ref impl: https://github.com/satoshilabs/slips/blob/master/slip-0010/testvectors.py
	func testMasterKeyXPUBCurve25519() throws {
		let seed = "65143633982249957359862559fd46e6aeb93e78477e73c6bd6d8f25d87c7972d587b6120134899667a3fec2631d31f3884d838fc1e65220c081c866ce64d676"
		let root = try HD.Root(seed: Data(hex: seed))

		let masterKey = try root.derivePrivateKey(path: HD.Path.Full(string: "m"), curve: Curve25519.self)
		XCTAssertEqual(masterKey.chainCode.chainCode.hex(), "25bf53d232d8208c709f9eaafcee90faab63d2a64dd9dec60449c6a0d688b209")
		XCTAssertEqual(masterKey.privateKey!.rawRepresentation.hex(), "d2508dc3a2a3208b154ecda6046c0878c6dd952dbaf9498f1dfbf413cdbd5283")
		XCTAssertEqual(masterKey.publicKey.rawRepresentation.hex(), "7229e3b98ffa35a4ce28b891ff0a9f95c9d959eff58d0e61015fab3a3b2d18f9")

		let expectedXPUB = "xpub661MyMwAqRbcEvENkx9zRzWhe2uCY1JrdmGH14FdS5hsoocYjCXnq9iwAZUbZDqJvDsTQ3TQczvdS7aCW7D351eMcpmJK3tvoNwvKKTskaa"
		let expectedXPRV = "xprv9s21ZrQH143K2S9uevcz4rZy614i8Yb1GYLgCfr1skAtw1HQBfDYHMQTKP4fWtkBbfN8JkCu4LttvCsW3FVwat7wfsfYNqJ7PAnRga2Ym8e"
		XCTAssertEqual(try masterKey.xpub(), expectedXPUB)

		XCTAssertEqual(try masterKey.xprv(), expectedXPRV)

		let fromXPUB = try HD.ExtendedKey<Curve25519>(string: expectedXPUB)
		XCTAssertEqual(fromXPUB, masterKey)

		// Assert roundtrip works
		XCTAssertEqual(try fromXPUB.xpub(), expectedXPUB)
	}

	/// Expected values generated with Python ref impl: https://github.com/satoshilabs/slips/blob/master/slip-0010/testvectors.py
	func testAtZeroHardenedXPUBCurve25519() throws {
		let seed = "65143633982249957359862559fd46e6aeb93e78477e73c6bd6d8f25d87c7972d587b6120134899667a3fec2631d31f3884d838fc1e65220c081c866ce64d676"
		let root = try HD.Root(seed: Data(hex: seed))

		let masterKey = try root.derivePrivateKey(path: HD.Path.Full(string: "m/0H"), curve: Curve25519.self)

		XCTAssertEqual(masterKey.chainCode.chainCode.hex(), "812165c6d57e66dd9dff33b3f4de959c1efa0f138462ffcc73ab553ec7cabbf7")
		XCTAssertEqual(masterKey.privateKey!.rawRepresentation.hex(), "4c9472a7ae25747fb14923901920a61585c5f4ede367605fbb973a4972213c65")
		XCTAssertEqual(masterKey.publicKey.rawRepresentation.hex(), "c9b399cb2a827a087499e5e49ea262abd887cec79618b6d9469f8bd1c82d43c5")

		let expectedXPRV = "xprv9v6J1jjy3YxVeth5t2wJV95iifNVMKuhDGpt99CAWJZCDEHBiBGc6KxXQd3ZdTFG9wDUTrR5MmGfEDvyriVHaM29EVCyBCoChHHjetrfWks"
		let expectedXPUB = "xpub695eRFGrsvWnsNmYz4UJrH2TGhCykndYaVkUwXbn4e6B62cLFiare8H1Fq8wnSHn3AzcMPC3oWX6d9muBk8JVCd162fqeTJ2eEo2o6iPnU8"
		XCTAssertEqual(try masterKey.xpub(), expectedXPUB)

		XCTAssertEqual(try masterKey.xprv(), expectedXPRV)

		let fromXPUB = try HD.ExtendedKey<Curve25519>(string: expectedXPUB)
		XCTAssertEqual(fromXPUB, masterKey)

		// Assert roundtrip works
		XCTAssertEqual(try fromXPUB.xpub(), expectedXPUB)
	}

	/// Expected values generated with Python ref impl: https://github.com/satoshilabs/slips/blob/master/slip-0010/testvectors.py
	func testMasterKeyXPUBP256() throws {
		let seed = "65143633982249957359862559fd46e6aeb93e78477e73c6bd6d8f25d87c7972d587b6120134899667a3fec2631d31f3884d838fc1e65220c081c866ce64d676"
		let root = try HD.Root(seed: Data(hex: seed))

		let masterKey = try root.derivePrivateKey(path: HD.Path.Full(string: "m"), curve: P256.self)
		XCTAssertEqual(masterKey.chainCode.chainCode.hex(), "e0c20fc585b3772f7a5dab38645e86dbcc1553e42390062027b26cf6c6417d80")
		XCTAssertEqual(masterKey.privateKey!.rawRepresentation.hex(), "324d9c52f0cc0230621df41b829f1e443041328347a75c5d36d06f0a767d4c1f")
		XCTAssertEqual(masterKey.publicKey.compressedRepresentation.hex(), "0276d40936bfc59cba63302c312eec2a834154542808e53b7cecc0904613f16173")

		let expectedXPUB = "xpub661MyMwAqRbcGnDkha9ei46T2eK9Pp6o5F1uhUseiuDGyaphTgwWzg1KStr8fgJHkws5hfgsUpyFRLE29kzQXm6n1hHu99A6B3CitJZ2CWB"
		let expectedXPRV = "xprv9s21ZrQH143K4J9HbYceLv9iUcUezMNwi26Ju6U3AZgJ6nVYv9dGSsgqbdJBquGTLbZ3rMVaSS1Uq1x9rGaw7Gq2xCsDKqDCEPf27u4ynxh"
		XCTAssertEqual(try masterKey.xpub(), expectedXPUB)

		XCTAssertEqual(try masterKey.xprv(), expectedXPRV)

		let fromXPUB = try HD.ExtendedKey<P256>(string: expectedXPUB)
		XCTAssertEqual(fromXPUB, masterKey)

		// Assert roundtrip works
		XCTAssertEqual(try fromXPUB.xpub(), expectedXPUB)
	}

	/// Expected values generated with Python ref impl: https://github.com/satoshilabs/slips/blob/master/slip-0010/testvectors.py
	func testAtZeroHardenedXPUBP256() throws {
		let seed = "65143633982249957359862559fd46e6aeb93e78477e73c6bd6d8f25d87c7972d587b6120134899667a3fec2631d31f3884d838fc1e65220c081c866ce64d676"
		let root = try HD.Root(seed: Data(hex: seed))

		let masterKey = try root.derivePrivateKey(path: HD.Path.Full(string: "m/0"), curve: P256.self)

		XCTAssertEqual(masterKey.chainCode.chainCode.hex(), "2d6dccd58d834233354dfdc34bced31611b62c6de89f3ea9f3c70054acb8079c")
		XCTAssertEqual(masterKey.privateKey!.rawRepresentation.hex(), "51bbea37e16408a6c01ed434a73250700d1516b5621dfc6f67073155ef930023")
		XCTAssertEqual(masterKey.publicKey.compressedRepresentation.hex(), "020bc8a8e5c6bceba993289643778edbb32d3e6eaf44b2a7dc6a0fea59c9ecad6a")

		let expectedXPRV = "xprv9veu6h7KNBjdSJii2VZu3meY5sGz6e8iH8yN7qS8czMscbEocVuLnw7KCW4z1YwnGh6qKpAqzapPeg4HJTyFhw6x8ZCyzpuF2BCfhpNCsbh"
		let expectedXPUB = "xpub69eFWCeDCZHvenoB8X6uQubGdu7UW6rZeMtxvDqkBKtrVPZxA3DbLjRo3kZwfhNFpLB4z7huLLoSo7FokpricFcUKbnEiesGvzqk331hMop"
		XCTAssertEqual(try masterKey.xpub(), expectedXPUB)

		XCTAssertEqual(try masterKey.xprv(), expectedXPRV)

		let fromXPUB = try HD.ExtendedKey<P256>(string: expectedXPUB)
		XCTAssertEqual(fromXPUB, masterKey)

		// Assert roundtrip works
		XCTAssertEqual(try fromXPUB.xpub(), expectedXPUB)
	}
}
