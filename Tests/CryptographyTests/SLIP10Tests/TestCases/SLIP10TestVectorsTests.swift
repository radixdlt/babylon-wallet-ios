@testable import Cryptography
import CryptoKit
import TestingPrelude

// MARK: - TestVector
struct TestVector<Curve: Slip10SupportedECCurve> {
	let seed: Data
	let vectorID: Int
	let testCases: [TestScenario]

	init(
		seed: String,
		vectorID: Int,
		testCases: [TestScenario]
	) throws {
		self.seed = try Data(hex: seed)
		self.vectorID = vectorID
		self.testCases = testCases
	}
}

// MARK: TestVector.TestScenario
extension TestVector {
	struct TestScenario {
		let path: HD.Path.Full
		let expected: Expected

		init(
			path: String,
			expected: Expected
		) throws {
			self.path = try HD.Path.Full(string: path)
			self.expected = expected
		}

		struct Expected {
			let fingerprint: Data
			let chainCode: Data
			let privateKey: Curve.PrivateKey
			let publicKey: Curve.PublicKey
			let xpriv: String
			let xpub: String

			init(
				fingerprint: String,
				chainCode: String,
				privateKey privateKeyHex: String,
				publicKey publicKeyHex: String,
				xpriv: String,
				xpub: String
			) throws {
				self.fingerprint = try Data(hex: fingerprint)
				self.chainCode = try Data(hex: chainCode)

				let privateKeyData = try Data(hex: privateKeyHex)
				self.privateKey = try Curve.PrivateKey(rawRepresentation: privateKeyData)

				var publicKeyData = try Data(hex: publicKeyHex)
				if publicKeyData.count == 33 {
					if Curve.slip10Curve == .curve25519 {
						assert(publicKeyData[0] == 0x00)
						publicKeyData = Data(publicKeyData.dropFirst())
					}
				}
				self.publicKey = try Curve.PublicKey(compressedRepresentation: publicKeyData)
				self.xpriv = xpriv
				self.xpub = xpub
			}
		}
	}
}

// MARK: - SLIP10TestVectorsTests
final class SLIP10TestVectorsTests: TestCase {
	func testPath_m() throws {
		let path: HD.Path.Full = "m"
		XCTAssertEqual(path.components, [.root(onlyPublic: false)])
	}

	func testPath_M() throws {
		let path: HD.Path.Full = "M"
		XCTAssertEqual(path.components, [.root(onlyPublic: true)])
	}

	func testPath_m44() throws {
		let path: HD.Path.Full = "m/44H"

		XCTAssertEqual(
			path.components,
			[
				.root(onlyPublic: false),
				.child(.harden(44)),
			]
		)
	}

	func testCurve25519ExtendedKeysMustBeHardened() throws {
		let seed = "000102030405060708090a0b0c0d0e0f"
		let root = try HD.Root(seed: Data(hex: seed))
		let path: HD.Path.Full = "m/1"

		XCTAssertThrowsError(
			try root.derivePrivateKey(path: path, curve: Curve25519.self),
			"Curve25519 requires hardened keys"
		) {
			guard let error = $0 as? HD.DerivationError else {
				return XCTFail("Wrong error type")
			}
			XCTAssertEqual(error, HD.DerivationError.curve25519RequiresHardenedPath)
		}

		XCTAssertNoThrow(
			try root.derivePrivateKey(path: path, curve: SECP256K1.self),
			"SECP256K1 accepts non hardened keys"
		)
	}

	func testAssociativity() throws {
		let seed = "000102030405060708090a0b0c0d0e0f"
		let root = try HD.Root(seed: Data(hex: seed))

		XCTAssertEqual(
			try root.derivePrivateKey(path: "m/1/2/3", curve: SECP256K1.self),
			try root.derivePrivateKey(path: "m/1/2").derivePrivateKey(component: 3)
		)

		XCTAssertEqual(
			try root.derivePrivateKey(path: "m/1/2/3", curve: SECP256K1.self),
			try root.derivePrivateKey(path: "m/1")
				.derivePrivateKey(component: 2)
				.derivePrivateKey(component: 3)
		)

		XCTAssertEqual(
			try root.derivePrivateKey(path: "m/1/2/3", curve: SECP256K1.self),
			try root.derivePrivateKey(path: "m")
				.derivePrivateKey(component: 1)
				.derivePrivateKey(component: 2)
				.derivePrivateKey(component: 3)
		)

		XCTAssertEqual(
			try root.derivePrivateKey(path: "m/1/2/3H", curve: SECP256K1.self),
			try root.derivePrivateKey(path: "m")
				.derivePrivateKey(component: 1)
				.derivePrivateKey(component: 2)
				.derivePrivateKey(component: .harden(3)
				)
		)

		XCTAssertEqual(
			try root.derivePrivateKey(path: "m/1/2/3H", curve: SECP256K1.self),
			try root.derivePrivateKey(path: "m/1").derivePrivateKey(path: "2/3H")
		)
	}

	func testAppendingRelativePathToFull() throws {
		let seed = "000102030405060708090a0b0c0d0e0f"
		let root = try HD.Root(seed: Data(hex: seed))
		let key: HD.ExtendedKey<SECP256K1> = try root.derivePrivateKey(path: "m/1").derivePrivateKey(path: "2/3")
		XCTAssertEqual(key.derivationPath.toString(), "m/1/2/3")
	}

	func testSerialize() throws {
		let seed = "000102030405060708090a0b0c0d0e0f"
		let root = try HD.Root(seed: Data(hex: seed))
		let key = try root.derivePrivateKey(path: "m", curve: Curve25519.self)
		let xpriv = "xprv9s21ZrQH143K3VX7GQTkxonbgca94bts9EdRC1ZKN2Z9BA3JXZxbUwo4kS28ECmXhK1NicjQ7yBwWbZXgjRVktP6Tzi4YqetK5ueSA2CaXP"
		XCTAssertEqual(try key.xprv(), xpriv)
		let fromXpriv = try HD.ExtendedKey<Curve25519>(string: xpriv)
		XCTAssertEqual(fromXpriv, key)
	}

	func testOnlyPublic() throws {
		let seed = "000102030405060708090a0b0c0d0e0f"
		let root = try HD.Root(seed: Data(hex: seed))
		let path: HD.Path.Full = "M"
		XCTAssertTrue(path.onlyPublic)
		let extendedKey: HD.ExtendedKey<Curve25519> = try root.derivePublicKey(path: path)
		XCTAssertEqual(extendedKey.publicKey.compressedRepresentation.hex(), "a4b2856bfec510abab89753fac1ac0e1112364e7d250545963f135f2a33188ed")
		XCTAssertEqual(extendedKey.derivationPath, .full(path))
		XCTAssertEqual(extendedKey.derivationPath.toString(), "M")
	}

	func testDeserialize() throws {
		let xpub = "xpub6GzMUbGykK9tAV4LW8nQv4RFefFkSr75D9uX5FUKxy5UgYE16xnXdEc8XCWbqMD6vzQDvf7BDsQ3yvoWS3VPVVTSwpxyncSJxXpdJBfP7bh"
		let key = try HD.ExtendedKey<Curve25519>(string: xpub)
		XCTAssertEqual(key.publicKey.hex, "3c24da049451555d51a7014a37337aa4e12d41e485abccfa46b47dfb2af54b7a")
		XCTAssertEqual(try key.xpub(), xpub)
	}

	func doTestSingleCase<C>(
		vector: TestVector<C>,
		testCaseIndex: Int,
		_ line: UInt = #line
	) throws where C: Slip10SupportedECCurve, C.PrivateKey: Equatable, C.PublicKey: Equatable {
		let root = try HD.Root(seed: vector.seed)
		let testCase = vector.testCases[testCaseIndex]
		try doTestCase(
			root: root,
			case: testCase,
			testIndex: testCaseIndex,
			line: line
		)
	}

	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-1-for-ed25519
	func testSlip10Vector1Curve25519() throws {
		try doTest(
			curve: Curve25519.self,
			vector: vector1Curve25519
		)
	}

	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-2-for-ed25519
	func testSlip10Vector2Curve25519() throws {
		try doTest(
			curve: Curve25519.self,
			vector: vector2Curve25519
		)
	}

	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-1-for-secp256k1
	func testSlip10Vector1Secp256k1() throws {
		try doTest(
			curve: SECP256K1.self,
			vector: vector1Secp256k1
		)
	}

	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-2-for-secp256k1
	func testSlip10Vector2Secp256k1() throws {
		try doTest(
			curve: SECP256K1.self,
			vector: vector2Secp256k1
		)
	}

	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-1-for-nist256p1
	func testSlip10Vector1P256() throws {
		try doTest(
			curve: P256.self,
			vector: vector1P256
		)
	}
}

extension SLIP10TestVectorsTests {
	// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#test-vector-2-for-nist256p1
	func testSlip10Vector2P256() throws {
		try doTest(
			curve: P256.self,
			vector: vector2P256
		)
	}

	func testP256PublicKeyInit() throws {
		let privateKeyHex = "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2"
		let publicKeyHex = "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8"
		let privateKey = try P256.Signing.PrivateKey(rawRepresentation: Data(hex: privateKeyHex))
		let publicKey = try P256.Signing.PublicKey(compressedRepresentation: Data(hex: publicKeyHex))
		XCTAssertEqual(publicKey.rawRepresentation.hex(), privateKey.publicKey.rawRepresentation.hex())
		XCTAssertEqual(privateKey.publicKey.rawRepresentation.hex().dropLast(64), publicKeyHex.dropFirst(2))

		XCTAssertNil(privateKey.publicKey.compactRepresentation)
		let compressedRepresentation = privateKey.publicKey.compressedRepresentation
		XCTAssertEqual(compressedRepresentation.hex(), publicKeyHex)
	}

	func testDerivationRetryP256() throws {
		try doTest(
			curve: P256.self,
			vector: derivationRetryVectorP256
		)
	}

	func testSeedRetryForP256() throws {
		try doTest(
			curve: P256.self,
			vector: seedRetryVectorP256
		)
	}
}

private let seedRetryVectorP256 = try! TestVector<P256>(
	seed: "a7305bc8df8d0951f0cb224c0e95d7707cbdf2c6ce7e8d481fec69c7ff5e9446",
	vectorID: 1,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "7762f9729fed06121fd13f326884c82f59aa95c57ac492ce8c9654e60efd130c",
				privateKey: "3b8c18469a4634517d6d0b65448f8e6c62091b45540a1743c5846be55d47d88f",
				publicKey: "0383619fadcde31063d8c5cb00dbfe1713f3e6fa169d8541a798752a1c1ca0cb20",
				xpriv: "xprv9s21ZrQH143K3FJBFR1wf6Z6KE4ZSVZdVnqgg5L7wUQk2cxFsu2doz79kejkeNjyCE9TXiE1udNFre4YnB3wzMpYTS7R25LovbEWwzCDG31",
				xpub: "xpub661MyMwAqRbcFjNeMSYx2EVpsFu3qxHUs1mHUTjjVowiuRHQRSLtMnRdbxFuAmh3q8DyQYbuHNjWnGK7rnoh6KWbvUqzQncbMyhuEdYhFJr"
			)
		),
	]
)

private let derivationRetryVectorP256 = try! TestVector<P256>(
	seed: "000102030405060708090a0b0c0d0e0f",
	vectorID: 1,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea",
				privateKey: "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2",
				publicKey: "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8",
				xpriv: "xprv9s21ZrQH143K3xbxu53vDH2NWbLKw5edQ3BCSX12Pknr1EA7QjAZPnd2jYvGvZ9RSwbcfeCZ5v2qZTTESRMTiAizzfQ1GUDeMWPyaXGcMfF",
				xpub: "xpub661MyMwAqRbcGSgS16avaQy74dApLYNUmG6oEuQdx6Kpt2VFxGUowawWaozRLQSe46f7nbyC5ZY8Tvvnc32WSiL3LSxFNvPgG84QVAyvBAw"
			)
		),
		.init(
			path: "m/28578H",
			expected: .init(
				fingerprint: "be6105b5",
				chainCode: "e94c8ebe30c2250a14713212f6449b20f3329105ea15b652ca5bdfc68f6c65c2",
				privateKey: "06f0db126f023755d0b8d86d4591718a5210dd8d024e3e14b6159d63f53aa669",
				publicKey: "02519b5554a4872e8c9c1c847115363051ec43e93400e030ba3c36b52a3e70a5b7",
				xpriv: "xprv9vJJjmzMMcm6yjgR7N6itvKbKZi82xc1KEBv4vsYnH9bY9GEzBVTepzjzM282F8tqAqabyTyULQigXmrNLx7FqeafRyRQBBLzSRDNpsJ4RV",
				xpub: "xpub69Hf9HXFBzKQCDktDPdjG4GKsbYcSRKrgT7WsKHALcgaQwbPXioiCdKDqccmhrdjQp4tzPunhR2zKdTaNzknMTrKMKW6PRPScHzE8cK85aU"
			)
		),
		.init(
			path: "m/28578H/33941",
			expected: .init(
				fingerprint: "3e2b7bc6",
				chainCode: "9e87fe95031f14736774cd82f25fd885065cb7c358c1edf813c72af535e83071",
				privateKey: "092154eed4af83e078ff9b84322015aefe5769e31270f62c3f66c33888335f3a",
				publicKey: "0235bfee614c0d5b2cae260000bb1d0d84b270099ad790022c1ae0b2e782efe120",
				xpriv: "xprv9wEnVkB4Pdq4LsNS1DeC16R19SsYisPBMyvxvVWXDDWvMsgQZYapSS2SE3YjZ86wrRffmpTDmF2KU5pa4pQ51LWWoixYbXWXZUzD6TiQZZB",
				xpub: "xpub6AE8uFhxE1PMZMSu7FBCNEMjhUi38L72jCrZisv8mZ3uEg1Z75u4zELv5Jv9k2dLoD3RZSnngSqZKpud8xwEq5opZKyyYR43Y1ERcveg6Xs"
			)
		),
	]
)

private let vector1P256 = try! TestVector<P256>(
	seed: "000102030405060708090a0b0c0d0e0f",
	vectorID: 1,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "beeb672fe4621673f722f38529c07392fecaa61015c80c34f29ce8b41b3cb6ea",
				privateKey: "612091aaa12e22dd2abef664f8a01a82cae99ad7441b7ef8110424915c268bc2",
				publicKey: "0266874dc6ade47b3ecd096745ca09bcd29638dd52c2c12117b11ed3e458cfa9e8",
				xpriv: "xprv9s21ZrQH143K3xbxu53vDH2NWbLKw5edQ3BCSX12Pknr1EA7QjAZPnd2jYvGvZ9RSwbcfeCZ5v2qZTTESRMTiAizzfQ1GUDeMWPyaXGcMfF",
				xpub: "xpub661MyMwAqRbcGSgS16avaQy74dApLYNUmG6oEuQdx6Kpt2VFxGUowawWaozRLQSe46f7nbyC5ZY8Tvvnc32WSiL3LSxFNvPgG84QVAyvBAw"
			)
		),
		.init(
			path: "m/0H",
			expected: .init(
				fingerprint: "be6105b5",
				chainCode: "3460cea53e6a6bb5fb391eeef3237ffd8724bf0a40e94943c98b83825342ee11",
				privateKey: "6939694369114c67917a182c59ddb8cafc3004e63ca5d3b84403ba8613debc0c",
				publicKey: "0384610f5ecffe8fda089363a41f56a5c7ffc1d81b59a612d0d649b2d22355590c",
				xpriv: "xprv9vJJjmzMMcPT7vuRQ3RUihF5SFms7a4j1CPuxok5NYqMd5dWjwXnmLTh8CzdBZJwHUybU3gSkKEAm86C27yde9ziL2PmahvMQSPhWSVAyVb",
				xpub: "xpub69Hf9HXFBywkLQytW4xV5qBozHcMX2naNRKWmC9gvtNLVsxfHUr3K8nAyWB6SFgSTJXtSoNqVPBjy5qeMcEb1EZhuPwUd7Sy2tSprcR3bN5"
			)
		),

		.init(
			path: "m/0H/1",
			expected: .init(
				fingerprint: "9b02312f",
				chainCode: "4187afff1aafa8445010097fb99d23aee9f599450c7bd140b6826ac22ba21d0c",
				privateKey: "284e9d38d07d21e4e281b645089a94f4cf5a5a81369acf151a1c3a57f18b2129",
				publicKey: "03526c63f8d0b4bbbf9c80df553fe66742df4676b241dabefdef67733e070f6844",
				xpriv: "xprv9wvN2XR2jhXFtoRvikiU4HhtMgFanjvmmMhRHj5KMKtHi2PN9aZPjAVWDLrjUbi5qejuMeQ3jH4ysGCVjVMMgERS3zCpv9DgbSEeHBnmR5k",
				xpub: "xpub6AuiS2wva55Z7HWPpnFURRecui65CCed8ad267UvufRGapiWh7seGxoz4e9nu9G1aBYqGsEV5RjhqLAjNWm294RZTgU8UgQ821iaPY5tazr"
			)
		),

		.init(
			path: "m/0H/1/2H",
			expected: .init(
				fingerprint: "b98005c1",
				chainCode: "98c7514f562e64e74170cc3cf304ee1ce54d6b6da4f880f313e8204c2a185318",
				privateKey: "694596e8a54f252c960eb771a3c41e7e32496d03b954aeb90f61635b8e092aa7",
				publicKey: "0359cf160040778a4b14c5f4d7b76e327ccc8c4a6086dd9451b7482b5a4972dda0",
				xpriv: "xprv9z2VpTyrSEs4AL8C9v1YLnB1eH8nJZHD3Je2xDsr6ZCkKPbuuJTQHNevwSHHzswEQqojkg9RnGZPFTwUA4e9q83KCKiCu7cFr7T2gWLtdcu",
				xpub: "xpub6D1rDyWkGcRMNpCfFwYYhv7kCJyGi214QXZdkcHTetjjCBw4SqmeqAyQnj8zdxbg7xNC4JjE25XwWqxxEMKdx3vafV7J2FKJ6XEEi4hp3WE"
			)
		),

		.init(
			path: "m/0H/1/2H/2",
			expected: .init(
				fingerprint: "0e9f3274",
				chainCode: "ba96f776a5c3907d7fd48bde5620ee374d4acfd540378476019eab70790c63a0",
				privateKey: "5996c37fd3dd2679039b23ed6f70b506c6b56b3cb5e424681fb0fa64caf82aaa",
				publicKey: "029f871f4cb9e1c97f9f4de9ccd0d4a2f2a171110c61178f84430062230833ff20",
				xpriv: "xprv9zenYLA3Ghj1MRMs8PSfUWGXXYsrL5JU5h5QZNcbnbgYyGV1fsHzy86gB4mYtZYxSKppYHoxQzCrv4QU9VjVuiynQcpC8bDdEGoVFMAsuoS",
				xpub: "xpub6De8wqgw75HJZuSLEQyfqeDG5aiLjY2KSv11Mm2DLwDXr4pADQcFWvRA2LL7pvxk3ujEA6fki2SN7aSTSBJvA7pDesLw3xapFzYFzfhF1R8"
			)
		),

		.init(
			path: "m/0H/1/2H/2/1000000000",
			expected: .init(
				fingerprint: "8b2b5c4b",
				chainCode: "b9b7b82d326bb9cb5b5b121066feea4eb93d5241103c9e7a18aad40f1dde8059",
				privateKey: "21c4f269ef0a5fd1badf47eeacebeeaa3de22eb8e5b0adcd0f27dd99d34d0119",
				publicKey: "02216cd26d31147f72427a453c443ed2cde8a1e53c9cc44e5ddf739725413fe3f4",
				xpriv: "xprvA3T1xmVE5egg5o6MTtExys1guLv6dBkjyQ5iDbJDZuoUbFCTtSgGWjU3WJjo8qstAV3pXygy91PAHKGA3UiZZCp8poRsezYt5etdF5AvQwJ",
				xpub: "xpub6GSNNH27v2EyJHApZumyLzxRTNkb2eUbLd1K1yhq8FLTU3XcRyzX4XnXMZmQnUwEEUAj4wLtQs6ePsffNJq9jf4nwCPgbjU3skwm3tBjEBn"
			)
		),
	]
)

private let vector2P256 = try! TestVector<P256>(
	seed: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542",
	vectorID: 2,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "96cd4465a9644e31528eda3592aa35eb39a9527769ce1855beafc1b81055e75d",
				privateKey: "eaa31c2e46ca2962227cf21d73a7ef0ce8b31c756897521eb6c7b39796633357",
				publicKey: "02c9e16154474b3ed5b38218bb0463e008f89ee03e62d22fdcc8014beab25b48fa",
				xpriv: "xprv9s21ZrQH143K3ZSLab6vRQo26pZT2EoQMivDWpf99qz9zhTXZ82neWFbQor8oTKHpiBiLaCQ4yEuGFUpCSETgkYx6B67tpaCDsSEx7dV1eh",
				xpub: "xpub661MyMwAqRbcG3WogcdvnYjkerPwRhXFiwqpKD4kiBX8sVng6fM3CJa5G4dUWuNtddwAc6hZTk5Mxzrr4YhLzryEpcGqcbqKPCmkV89g3j6"
			)
		),
		.init(
			path: "m/0",
			expected: .init(
				fingerprint: "607f628f",
				chainCode: "84e9c258bb8557a40e0d041115b376dd55eda99c0042ce29e81ebe4efed9b86a",
				privateKey: "d7d065f63a62624888500cdb4f88b6d59c2927fee9e6d0cdff9cad555884df6e",
				publicKey: "039b6df4bece7b6c81e2adfeea4bcf5c8c8a6e40ea7ffa3cf6e8494c61a1fc82cc",
				xpriv: "xprv9ucHRfZXkJ1nKcUniu1XjUX6hQ36Cd8U9xHjsW5pySTfpmTFfZnEAmQuQ4vCSoChGYhBJnD2v7t1joVKiBkPuaAiusUxo84jLifUkipmXZo",
				xpub: "xpub68bdqB6Rafa5Y6ZFpvYY6cTqFRsac5rKXBDLftVSXmzehZnQD76UiZjPFMS7d2hriw5abC79Wz7EmoNTxsYo3o6vbpKP4M6uANVfNXYvGFT"
			)
		),
		.init(
			path: "m/0/2147483647H",
			expected: .init(
				fingerprint: "946d2a54",
				chainCode: "f235b2bc5c04606ca9c30027a84f353acf4e4683edbd11f635d0dcc1cd106ea6",
				privateKey: "96d2ec9316746a75e7793684ed01e3d51194d81a42a3276858a5b7376d4b94b9",
				publicKey: "02f89c5deb1cae4fedc9905f98ae6cbf6cbab120d8cb85d5bd9a91a72f4c068c76",
				xpriv: "xprv9wsZH2aigThGRMSkWmfE2Q9tnAQjKHG7P4nNwUmFkEHWRA82JNYhDS4qFhwkb62hQ9LU2MzMdsxAegwoDDhG7w3ZHjkhqJXXuvw6qmCbPyA",
				xpub: "xpub6ArugY7cWqFZdqXDcoCEPY6dLCFDijyxkHhyjsAsJZpVHxTAqurwmEPK6yias9BZ48epVGA4c8zL8HsWVj5B4UGrVvuWQ17kPayfWLVYzax"
			)
		),
		.init(
			path: "m/0/2147483647H/1",
			expected: .init(
				fingerprint: "218182d8",
				chainCode: "7c0b833106235e452eba79d2bdd58d4086e663bc8cc55e9773d2b5eeda313f3b",
				privateKey: "974f9096ea6873a915910e82b29d7c338542ccde39d2064d1cc228f371542bbc",
				publicKey: "03abe0ad54c97c1d654c1852dfdc32d6d3e487e75fa16f0fd6304b9ceae4220c64",
				xpriv: "xprv9xuhcJpU8VhLvKHrFjwQcMN7q6W2rNNPLwPXUned1NRWCsYb3gk274vLSCmbW4tsDHu2rh7cevEkDVeRZZqodJeKSNwMGV7AgDqqEk5MUsV",
				xpub: "xpub6Bu41pMMxsFe8oNKMmUQyVJrP8LXFq6EiAK8HB4EZhxV5fsjbE4GesEpHVuAUP2Diy7h2EroQULLrk9iDKZRqaLzvWNJkZ3udasWSTERppf"
			)
		),
		.init(
			path: "m/0/2147483647H/1/2147483646H",
			expected: .init(
				fingerprint: "931223e4",
				chainCode: "5794e616eadaf33413aa309318a26ee0fd5163b70466de7a4512fd4b1a5c9e6a",
				privateKey: "da29649bbfaff095cd43819eda9a7be74236539a29094cd8336b07ed8d4eff63",
				publicKey: "03cb8cb067d248691808cd6b5a5a06b48e34ebac4d965cba33e6dc46fe13d9b933",
				xpriv: "xprvA1dFUZsG4Smtv4Kdj1TtPyiCnaDwL19dB2ZpYp43XeK7S5KzDz4YmCkycwrVjBTTE1BhbBgNQffmTxjZKecVH3Vd4iuTRvDDVDmNWKwGdUd",
				xpub: "xpub6Ecbt5Q9tpLC8YQ6q2ztm7ewLc4RjTsUYFVRMCTf5yr6Jsf8mXNoK15TUEia6ifNA2CfJZ21SiHDVaP1HsyWEBehzsFH7FdTVsbzg8wYEpf"
			)
		),
		.init(
			path: "m/0/2147483647H/1/2147483646H/2",
			expected: .init(
				fingerprint: "956c4629",
				chainCode: "3bfb29ee8ac4484f09db09c2079b520ea5616df7820f071a20320366fbe226a7",
				privateKey: "bb0a77ba01cc31d77205d51d08bd313b979a71ef4de9b062f8958297e746bd67",
				publicKey: "020ee02e18967237cf62672983b253ee62fa4dd431f8243bfeccdf39dbe181387f",
				xpriv: "xprvA3XPVVqLYFuF18tfqC9ZHaR7CTmYzk9rz2ZFBewjrn9E9ecPAiRpM5kxrejBZAfBQ8aVxSYbtpJjtThnZqQC5BMqB6p93ZZt5kVyeXqnxDK",
				xpub: "xpub6GWju1NENdTYDcy8wDgZeiMqkVc3QCsiMFUqz3MMR7gD2SwXiFk4tt5ShtT8GYfx3MZhYsP4XJ3ZiNfTUiu9WrLtdMym2u8uJZxf45wGeoh"
			)
		),
	]
)

private let vector1Curve25519 = try! TestVector<Curve25519>(
	seed: "000102030405060708090a0b0c0d0e0f",
	vectorID: 1,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "90046a93de5380a72b5e45010748567d5ea02bbf6522f979e05c0d8d8ca9fffb",
				privateKey: "2b4be7f19ee27bbf30c667b642d5f4aa69fd169872f8fc3059c08ebae2eb19e7",
				publicKey: "00a4b2856bfec510abab89753fac1ac0e1112364e7d250545963f135f2a33188ed",
				xpriv: "xprv9s21ZrQH143K3VX7GQTkxonbgca94bts9EdRC1ZKN2Z9BA3JXZxbUwo4kS28ECmXhK1NicjQ7yBwWbZXgjRVktP6Tzi4YqetK5ueSA2CaXP",
				xpub: "xpub661MyMwAqRbcFybaNRzmKwjLEeQdU4ciWTZ1zPxvvN683xNT57Gr2k7Ybe5sLdMAtszjE1cd1Q1Wmb82QjvjtYomxGdbfLN5wnDyCpd3t6e"
			)
		),

		.init(
			path: "m/0H",
			expected: .init(
				fingerprint: "ddebc675",
				chainCode: "8b59aa11380b624e81507a27fedda59fea6d0b779a778918a2fd3590e16e9c69",
				privateKey: "68e0fe46dfb67e368c75379acec591dad19df3cde26e63b93a8e704f1dade7a3",
				publicKey: "008c8a13df77a28f3445213a0f432fde644acaa215fc72dcdf300d5efaa85d350c",
				xpriv: "xprv9vXkeS59SNYr567MAZPtjkhjp645NGj7VTAGZ7LqaZtvfgKGDEyv27HMw6nfHWcSnKnJ6BtTKrhgsKUkxtR3K6juACC8Qw4DRWr7hrAJxKX",
				xpub: "xpub69X73wc3Gk79HaBpGavu6teUN7tZmjSxrg5sMVkT8uRuYUeQknJAZubqnJCeGqq5Tm1SamntUPcnAAkLaZMjXjAHBM85e5L4bV3HebS74ou"
			)
		),

		.init(
			path: "m/0H/1H",
			expected: .init(
				fingerprint: "13dab143",
				chainCode: "a320425f77d1b5c2505a6b1b27382b37368ee640e3557c315416801243552f14",
				privateKey: "b1d0bad404bf35da785a64ca1ac54b2617211d2777696fbffaf208f746ae84f2",
				publicKey: "001932a5270f335bed617d5b935c80aedb1a35bd9fc1e31acafd5372c30f5c1187",
				xpriv: "xprv9vvkCbYPgLdiGwVBabM8r6NUDKGGerPb4t2kbqAJDWWbbn68EG4Zmwzpq7eRjbQ78MFnnyasFqt9WiEEnVBpE878KQB3fxYjCkUcUjLBXjg",
				xpub: "xpub69v6c75HWiC1VRZegct9DEKCmM6m4K7SS6xMQDZumr3aUaRGmoNpKkKJgHdVR1RL6VjDxUBWyRAJwJLPbBQmEvnT7k9MSXinpyGcWTDKPPt"
			)
		),

		.init(
			path: "m/0H/1H/2H",
			expected: .init(
				fingerprint: "ebe4cb29",
				chainCode: "2e69929e00b5ab250f49c3fb1c12f252de4fed2c1db88387094a0f8c4c9ccd6c",
				privateKey: "92a5b23c0b8a99e37d07df3fb9966917f5d06e02ddbd909c7e184371463e9fc9",
				publicKey: "00ae98736566d30ed0e9d2f4486a64bc95740d89c7db33f52121f8ea8f76ff0fc1",
				xpriv: "xprv9zPyrQoMg2watGWZTFYWrcgL9tEt7fannRDrHSzX7ZwuGqSzRn87jeRaTtEbwReQdnWzWDk82R6o13r56u9Q9w6WecqiswiQbsknzXnEnCR",
				xpub: "xpub6DPLFvLFWQVt6kb2ZH5XDkd4hv5NX8Je9e9T5qQ8fuUt9dn8yKSNHSk4K5bBvr3j4VcTF2zJoWanvQf59zz4FDokFj5mNHUqdgXj5z4s4mz"
			)
		),

		.init(
			path: "m/0H/1H/2H/2H",
			expected: .init(
				fingerprint: "316ec1c6",
				chainCode: "8f6d87f93d750e0efccda017d662a1b31a266e4a6f5993b15f5c1f07f74dd5cc",
				privateKey: "30d1dc7e5fc04c31219ab25a27ae00b50f6fd66622f6e9c913253d6511d1e662",
				publicKey: "008abae2d66361c879b900d204ad2cc4984fa2aa344dd7ddc46007329ac76c429c",
				xpriv: "xprv9zudGmYJHgxA7mY2TFMeWFv18jPZw3oy2cg5C3CRPwVrGyrotS4wDjxtWsnswR7mmG1ysEZBVZscqbymKaGCQkbiA6QEka9tBALGqmt4d2w",
				xpub: "xpub6DtygH5C84WTLFcVZGtesPrjgmE4LWXpPqbfzRc2xH2q9nBxRyPBmYHNN5ckfXGLJjMXc2BPePB5PzJFJypfftX21G3eJYWVzpSF899Nxeq"
			)
		),

		.init(
			path: "m/0H/1H/2H/2H/1000000000H",
			expected: .init(
				fingerprint: "d6322ccd",
				chainCode: "68789923a0cac2cd5a29172a475fe9e0fb14cd6adb5ad98a3fa70333e7afa230",
				privateKey: "8f94d394a8e8fd6b1bc2f3f49f5c47e385281d5c17e65324b0f62483e37e8793",
				publicKey: "003c24da049451555d51a7014a37337aa4e12d41e485abccfa46b47dfb2af54b7a",
				xpriv: "xprvA41155k5uwbawzysQ7FQYvUX6dRG3PPDqvyvGs4iQdYVojtrZRUH5SHeg2153NJCehKfTCRcJj2JYhtZnZunAhM6U6JsTdEhB5h6dxH3dg4",
				xpub: "xpub6GzMUbGykK9tAV4LW8nQv4RFefFkSr75D9uX5FUKxy5UgYE16xnXdEc8XCWbqMD6vzQDvf7BDsQ3yvoWS3VPVVTSwpxyncSJxXpdJBfP7bh"
			)
		),
	]
)

private let vector2Curve25519 = try! TestVector<Curve25519>(
	seed: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542",
	vectorID: 2,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "ef70a74db9c3a5af931b5fe73ed8e1a53464133654fd55e7a66f8570b8e33c3b",
				privateKey: "171cb88b1b3c1db25add599712e36245d75bc65a1a5c9e18d76f9f2b1eab4012",
				publicKey: "008fe9693f8fa62a4305a140b9764c5ee01e455963744fe18204b4fb948249308a",
				xpriv: "xprv9s21ZrQH143K4Sd1z5fLT9D6CsVWg33mA1TDfKPzKavYR47H1cJaX16paqoyUuw3g1Zm6GHruGNpXqdVk8BVoZ8bLE3DYQpudN4C9H391kJ",
				xpub: "xpub661MyMwAqRbcGvhV67CLpH9pkuL15VmcXENpThobsvTXHrSRZ9cq4oRJS3sTEY93ZJeoRxEdEofbMdPYQRWixwx2aFSWV51s3n2NQbe4oqt"
			)
		),

		.init(
			path: "m/0H",
			expected: .init(
				fingerprint: "31981b50",
				chainCode: "0b78a3226f915c082bf118f83618a618ab6dec793752624cbeb622acb562862d",
				privateKey: "1559eb2bbec5790b0c65d8693e4d0875b1747f4970ae8b650486ed7470845635",
				publicKey: "0086fab68dcb57aa196c77c5f264f215a112c22a912c10d123b0d03c3c28ef1037",
				xpriv: "xprv9uGHh49ujaoHqQ2cp8sRmUALBStm8demw229jvVQDFCxgYZbGhgTo58JJPWE84Yqukks3CEsoUX1T61y5r6pMh59woxdZbncKbJsHSMbq42",
				xpub: "xpub68Fe6ZgoZxMb3t75vAQS8c74jUjFY6NdJEwkYJu1majwZLtjpEziLsSn9bWYgvf5Uv6JzZZZHZJpo431VZhjXdehLdTdYaRyXLF7w24AkYs"
			)
		),

		.init(
			path: "m/0H/2147483647H",
			expected: .init(
				fingerprint: "1e9411b1",
				chainCode: "138f0b2551bcafeca6ff2aa88ba8ed0ed8de070841f0c4ef0165df8181eaad7f",
				privateKey: "ea4f5bfe8694d8bb74b7b59404632fd5968b774ed545e810de9c32a4fb4192f4",
				publicKey: "005ba3b9ac6e90e83effcd25ac4e58a1365a9e35a3d3ae5eb07b9e4d90bcf7506d",
				xpriv: "xprv9w1KNACRREEJrriwWHinXRoEpET3c9wfmBe5Giw1ju9EJfwe793TKgZz9LYKq4cJoMpoBzTAToDFv7GctoZnpBoSEHRaCPpubaCLeqXanCu",
				xpub: "xpub69zfmfjKFbnc5LoQcKFntZjyNGHY1cfX8QZg57LdJEgDBUGnegMhsUtTzWbmbPJ8bwhk9wAv4Pb27p7tXpg14EdjtQzzj4GGFQXfUhGA9X6"
			)
		),

		.init(
			path: "m/0H/2147483647H/1H",
			expected: .init(
				fingerprint: "fcadf38c",
				chainCode: "73bd9fff1cfbde33a1b846c27085f711c0fe2d66fd32e139d3ebc28e5a4a6b90",
				privateKey: "3757c7577170179c7868353ada796c839135b3d30554bbb74a4b1e4a5a58505c",
				publicKey: "002e66aa57069c86cc18249aecf5cb5a9cebbfd6fadeab056254763874a9352b45",
				xpriv: "xprv9zX8u2jhF8C9xiNBaWcAbYdMVhQRF26KVJx2HsSHrUa3z9dobfGEAyP5gpUGyyCecurJkGKZWq15f1L4UYcfcVnoMmzwoXaH3ghtQwq4soQ",
				xpub: "xpub6DWVJYGb5VkTBCSegY9Axga63jEueUpArXsd6FquQp72rwxx9CaUimhZY1YcfWS4PrZijf3kgPDHBK4LzWxs5Zp9ao3TkXCnFJqGH3vaCLw"
			)
		),

		.init(
			path: "m/0H/2147483647H/1H/2147483646H",
			expected: .init(
				fingerprint: "aca70953",
				chainCode: "0902fe8a29f9140480a00ef244bd183e8a13288e4412d8389d140aac1794825a",
				privateKey: "5837736c89570de861ebc173b1086da4f505d4adb387c6a1b1342d5e4ac9ec72",
				publicKey: "00e33c0f7d81d843c572275f287498e8d408654fdf0d1e065b84e2e6f157aab09b",
				xpriv: "xprvA1pA1PtdkCdx5FhjvoYZpGck3VgU3GtAoXEWJwWmT15vg34XeYMUAuw15e3VzZYnvSFERzrB4Pih42T1D7WFmNmN5Y1S77jdY2PWZoSGjLd",
				xpub: "xpub6EoWQuRXaaCFHjnD2q5aBQZUbXWxSjc2AkA77KvP1LcuYqPgC5fiiiFUvrF17PCqcyfR6sG8G13RmjbNvmuHzqvrBZY335vCKS9NxhA1ygr"
			)
		),

		.init(
			path: "m/0H/2147483647H/1H/2147483646H/2H",
			expected: .init(
				fingerprint: "422c654b",
				chainCode: "5d70af781f3a37b829f0d060924d5e960bdc02e85423494afc0b1a41bbe196d4",
				privateKey: "551d333177df541ad876a60ea71f00447931c0a9da16f227c11ea080d7391b8d",
				publicKey: "0047150c75db263559a70d5778bf36abbab30fb061ad69f69ece61a72b0cfa4fc0",
				xpriv: "xprvA2uu4eHvBTCGQj4XrxztSJ323FeUN4fiFpMPYLEQXeX6CMGxqwTYoVCKyczbQmhPTHN4J3MxfvSu3pPCKRmG5SbooBcnq3TUCLvZ417Cspw",
				xpub: "xpub6FuFU9pp1pkZdD8zxzXtoRykbHUxmXPZd3GzLie25z4559c7PUmoMHWopp2h5KfxEyWUdL1bNPxncaNmxdzf3qpLA3eJhdgHWb1xf4Mc7Ff"
			)
		),
	]
)

private let vector1Secp256k1 = try! TestVector<SECP256K1>(
	seed: "000102030405060708090a0b0c0d0e0f",
	vectorID: 1,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508",
				privateKey: "e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35",
				publicKey: "0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2",
				xpriv: "xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi",
				xpub: "xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8"
			)
		),

		.init(
			path: "m/0H",
			expected: .init(
				fingerprint: "3442193e",
				chainCode: "47fdacbd0f1097043b78c63c20c34ef4ed9a111d980047ad16282c7ae6236141",
				privateKey: "edb2e14f9ee77d26dd93b4ecede8d16ed408ce149b6cd80b0715a2d911a0afea",
				publicKey: "035a784662a4a20a65bf6aab9ae98a6c068a81c52e4b032c0fb5400c706cfccc56",
				xpriv: "xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7",
				xpub: "xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw"
			)
		),
		.init(
			path: "m/0H/1",
			expected: .init(
				fingerprint: "5c1bd648",
				chainCode: "2a7857631386ba23dacac34180dd1983734e444fdbf774041578e9b6adb37c19",
				privateKey: "3c6cb8d0f6a264c91ea8b5030fadaa8e538b020f0a387421a12de9319dc93368",
				publicKey: "03501e454bf00751f24b1b489aa925215d66af2234e3891c3b21a52bedb3cd711c",
				xpriv: "xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs",
				xpub: "xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ"
			)
		),
		.init(
			path: "m/0H/1/2H",
			expected: .init(
				fingerprint: "bef5a2f9",
				chainCode: "04466b9cc8e161e966409ca52986c584f07e9dc81f735db683c3ff6ec7b1503f",
				privateKey: "cbce0d719ecf7431d88e6a89fa1483e02e35092af60c042b1df2ff59fa424dca",
				publicKey: "0357bfe1e341d01c69fe5654309956cbea516822fba8a601743a012a7896ee8dc2",
				xpriv: "xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM",
				xpub: "xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5"
			)
		),
		.init(
			path: "m/0H/1/2H/2",
			expected: .init(
				fingerprint: "ee7ab90c",
				chainCode: "cfb71883f01676f587d023cc53a35bc7f88f724b1f8c2892ac1275ac822a3edd",
				privateKey: "0f479245fb19a38a1954c5c7c0ebab2f9bdfd96a17563ef28a6a4b1a2a764ef4",
				publicKey: "02e8445082a72f29b75ca48748a914df60622a609cacfce8ed0e35804560741d29",
				xpriv: "xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334",
				xpub: "xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV"
			)
		),
		.init(
			path: "m/0H/1/2H/2/1000000000",
			expected: .init(
				fingerprint: "d880d7d8",
				chainCode: "c783e67b921d2beb8f6b389cc646d7263b4145701dadd2161548a8b078e65e9e",
				privateKey: "471b76e389e528d6de6d816857e012c5455051cad6660850e58372a6c3e6e7c8",
				publicKey: "022a471424da5e657499d1ff51cb43c47481a03b1e77f951fe64cec9f5a48f7011",
				xpriv: "xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76",
				xpub: "xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy"
			)
		),
	]
)

private let vector2Secp256k1 = try! TestVector<SECP256K1>(
	seed: "fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542",
	vectorID: 2,
	testCases: [
		.init(
			path: "m",
			expected: .init(
				fingerprint: "00000000",
				chainCode: "60499f801b896d83179a4374aeb7822aaeaceaa0db1f85ee3e904c4defbd9689",
				privateKey: "4b03d6fc340455b363f51020ad3ecca4f0850280cf436c70c727923f6db46c3e",
				publicKey: "03cbcaa9c98c877a26977d00825c956a238e8dddfbd322cce4f74b0b5bd6ace4a7",
				xpriv: "xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U",
				xpub: "xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB"
			)
		),
		.init(
			path: "m/0",
			expected: .init(
				fingerprint: "bd16bee5",
				chainCode: "f0909affaa7ee7abe5dd4e100598d4dc53cd709d5a5c2cac40e7412f232f7c9c",
				privateKey: "abe74a98f6c7eabee0428f53798f0ab8aa1bd37873999041703c742f15ac7e1e",
				publicKey: "02fc9e5af0ac8d9b3cecfe2a888e2117ba3d089d8585886c9c826b6b22a98d12ea",
				xpriv: "xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt",
				xpub: "xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH"
			)
		),
		.init(
			path: "m/0/2147483647H",
			expected: .init(
				fingerprint: "5a61ff8e",
				chainCode: "be17a268474a6bb9c61e1d720cf6215e2a88c5406c4aee7b38547f585c9a37d9",
				privateKey: "877c779ad9687164e9c2f4f0f4ff0340814392330693ce95a58fe18fd52e6e93",
				publicKey: "03c01e7425647bdefa82b12d9bad5e3e6865bee0502694b94ca58b666abc0a5c3b",
				xpriv: "xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9",
				xpub: "xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a"
			)
		),
		.init(
			path: "m/0/2147483647H/1",
			expected: .init(
				fingerprint: "d8ab4937",
				chainCode: "f366f48f1ea9f2d1d3fe958c95ca84ea18e4c4ddb9366c336c927eb246fb38cb",
				privateKey: "704addf544a06e5ee4bea37098463c23613da32020d604506da8c0518e1da4b7",
				publicKey: "03a7d1d856deb74c508e05031f9895dab54626251b3806e16b4bd12e781a7df5b9",
				xpriv: "xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef",
				xpub: "xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon"
			)
		),
		.init(
			path: "m/0/2147483647H/1/2147483646H",
			expected: .init(
				fingerprint: "78412e3a",
				chainCode: "637807030d55d01f9a0cb3a7839515d796bd07706386a6eddf06cc29a65a0e29",
				privateKey: "f1c7c871a54a804afe328b4c83a1c33b8e5ff48f5087273f04efa83b247d6a2d",
				publicKey: "02d2b36900396c9282fa14628566582f206a5dd0bcc8d5e892611806cafb0301f0",
				xpriv: "xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc",
				xpub: "xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL"
			)
		),
		.init(
			path: "m/0/2147483647H/1/2147483646H/2",
			expected: .init(
				fingerprint: "31a507b8",
				chainCode: "9452b549be8cea3ecb7a84bec10dcfd94afe4d129ebfd3b3cb58eedf394ed271",
				privateKey: "bb7d39bdb83ecf58f2fd82b6d918341cbef428661ef01ab97c28a4842125ac23",
				publicKey: "024d902e1a2fc7a8755ab5b694c575fce742c48d9ff192e63df5193e4c7afe1f9c",
				xpriv: "xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j",
				xpub: "xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt"
			)
		),
	]
)

extension SLIP10TestVectorsTests {
	private func doTest<C>(
		curve: C.Type,
		vector: TestVector<C>,
		_ line: UInt = #line
	) throws where C: Slip10SupportedECCurve, C.PrivateKey: Equatable, C.PublicKey: Equatable {
		let root = try HD.Root(seed: vector.seed)

		try vector.testCases.enumerated().forEach { testCaseIndex, testCase in
			try doTestCase(
				root: root,
				case: testCase,
				testIndex: testCaseIndex,
				line: line
			)
		}
	}

	private func doTestCase<C>(
		root: HD.Root,
		case testCase: TestVector<C>.TestScenario,
		testIndex: Int,
		line: UInt = #line
	) throws where C: Slip10SupportedECCurve, C.PrivateKey: Equatable, C.PublicKey: Equatable {
		func doInnerTest(childKey: HD.ExtendedKey<C>, expectPrivateToBePresent: Bool = true) throws {
			XCTAssertEqual(
				childKey.chainCode.chainCode.hex(),
				testCase.expected.chainCode.hex(),
				"ChainCode mismatch",
				line: line
			)

			XCTAssertEqual(
				childKey.fingerprint.fingerprint.hex(),
				testCase.expected.fingerprint.hex(),
				"Fingerprint mismatch",
				line: line
			)

			XCTAssertEqual(
				childKey.publicKey,
				testCase.expected.publicKey,
				"PublicKey mismatch",
				line: line
			)

			XCTAssertEqual(
				childKey.derivationPath.toString(),
				testCase.path.toString(),
				"Derivation path mismatch",
				line: line
			)

			XCTAssertEqual(
				try childKey.xpub(),
				testCase.expected.xpub,
				"Serialized XPUB mismatch",
				line: line
			)

			let keyFromXpub = try HD.ExtendedKey<C>(string: testCase.expected.xpub)
			XCTAssertEqual(
				keyFromXpub,
				childKey,
				"Deralized XPUB does not match derived key",
				line: line
			)

			if expectPrivateToBePresent {
				let extendedPrivateKey = try XCTUnwrap(childKey.privateKey, line: line)

				XCTAssertEqual(
					extendedPrivateKey.rawRepresentation.hex(),
					testCase.expected.privateKey.hex,
					"PrivateKey mismatch",
					line: line
				)

				XCTAssertEqual(
					try childKey.xprv(),
					testCase.expected.xpriv,
					"Serialized XPRIV does not match expected xpriv string.",
					line: line
				)

				let keyFromXpriv = try HD.ExtendedKey<C>(string: testCase.expected.xpriv)

				XCTAssertEqual(
					keyFromXpriv,
					childKey,
					"Deserialized key from XPRIV does not match derived key",
					line: line
				)
			}
		}

		try doInnerTest(
			childKey: root.derivePrivateKey(path: testCase.path)
		)

		let depth = try testCase.path.depth()
		if !(C.isCurve25519 && depth > 2) {
			try doInnerTest(
				childKey: root.derivePublicKey(path: testCase.path),
				expectPrivateToBePresent: false
			)
		}
	}
}

// MARK: P256
extension Slip10CurveType {
	/// The elliptic curve `P256`, `secp256r1`, `prime256v1` or as SLIP-0010 calls it `Nist256p1`
	public static let p256 = Self(
		// For some strange reason SLIP-0010 calls P256 "Nist256p1" instead of
		// either `P256`, `secp256r1` or `prime256v1`. Unfortunate!
		// https://github.com/satoshilabs/slips/blob/master/slip-0010.md#master-key-generation
		slip10CurveID: "Nist256p1 seed",
		curveOrder: BigUInt("FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551", radix: 16)!
	)
}

// MARK: - P256 + Slip10SupportedECCurve
extension P256: Slip10SupportedECCurve {
	public typealias PrivateKey = P256.Signing.PrivateKey
	public typealias PublicKey = P256.Signing.PublicKey
	public static let slip10Curve = Slip10CurveType.p256
}

// MARK: - P256.Signing.PrivateKey + ECPrivateKey
extension P256.Signing.PrivateKey: ECPrivateKey {}

// MARK: - P256.Signing.PublicKey + ECPublicKey
extension P256.Signing.PublicKey: ECPublicKey {}
