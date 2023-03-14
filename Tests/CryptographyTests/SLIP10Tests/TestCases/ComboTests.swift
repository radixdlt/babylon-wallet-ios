@testable import Cryptography
import CryptoKit
import TestingPrelude

extension HD.Root {
	public init(mnemonic: Mnemonic, passphrase: String = "") throws {
		try self.init(seed: mnemonic.seed(passphrase: passphrase))
	}
}

// MARK: - ComboTests
final class ComboTests: TestCase {
	func testInterface() throws {
		let mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
		let root = try HD.Root(mnemonic: mnemonic)
		let path = try HD.Path.Full(string: "m/44'/1022'/0'/0'/0'")
		let extendedKey = try root.derivePrivateKey(path: path, curve: Curve25519.self)
		XCTAssertEqual(
			try extendedKey.xpub(),
			"xpub6H2b8hB6ihwjSHhARVNGsdHordgGw599Mz8AETeL3nqmG6NuHfa81uczPbUGK4dGTVQTpmW5jPJz57scwiQYKxzN3Yuct6KRM3FemUNiFsn"
		)
	}

	func test_signature_format_conversion() throws {
		let rawHex = "2c799da598d2a001ca560afde4ed9c877028d976a793772666119c266549be368d0aea03e131ecbba884250b18179ecf3c9fcd4840c6347dc465a7db2f2a240d01"
		let raw = try Data(hex: rawHex)
		let signatureRaw = try ECDSASignatureRecoverable(rawRepresentation: raw)
		try XCTAssertEqual(signatureRaw.radixSerialize().hex, "0136be4965269c1166267793a776d92870879cede4fd0a56ca01a0d298a59d792c0d242a2fdba765c47d34c64048cd9f3ccf9e17180b2584a8bbec31e103ea0a8d")
		let fromRadixFormat = try ECDSASignatureRecoverable(radixFormat: "0136be4965269c1166267793a776d92870879cede4fd0a56ca01a0d298a59d792c0d242a2fdba765c47d34c64048cd9f3ccf9e17180b2584a8bbec31e103ea0a8d")
		XCTAssertEqual(fromRadixFormat.rawRepresentation.hex, rawHex)
	}

	func test_secp256k1() throws {
		let privateKey = try K1.PrivateKey.generateNew()
		let publicKey = privateKey.publicKey
		let unhashed = "Hey".data(using: .utf8)!
		let signature = try privateKey.ecdsaSignRecoverable(unhashed: unhashed)
		var isValid = false

		isValid = try publicKey.isValid(signature: signature, unhashed: unhashed)
		XCTAssertTrue(isValid)

		let roundtripSig = try ECDSASignatureRecoverable(radixFormat: signature.radixSerialize())
		isValid = try publicKey.isValid(signature: roundtripSig, unhashed: unhashed)
		XCTAssertTrue(isValid)
	}

	func test_apa() throws {
		/*
		 signed unhashed
		  5c210221090701070b0a5c1f0000000000000a661f0000000000000a991759bf467305d1220001b1035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f01000900e1f505080000210220220327038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c086c6f636b5f6665652007245c2101b50000e8890423c78a00000000000000000000000000000000000000000000000027038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c1277697468647261775f62795f616d6f756e742007405c2102b50000b0d86b9088a60000000000000000000000000000000000000000000000008200000000000000000000000000000000000000000000000000000027038108f45e17ae7960dce161b9f3c718e055191a909272995b4ff19d040c0d6465706f7369745f62617463682007055c2101a200202000,

		  hashed message: c60e774c1e3c3a53df761eb336efc4c3a89f7265af305dcb2513113c7a44af7e

		  publicKey: 035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f

		  sig.raw: 3901cf34cac6561eb9f1f68ff8bf84361ef005edd35f693e150046976c9d4a19aa71d74a9378119e186e2dcc28e9908ad2760e2d89f1f077431eb3e1f5c4bd0e01,

		  sig.rdx: 01194a9d6c974600153e695fd3ed05f01e3684bff88ff6f1b91e56c6ca34cf01390ebdc4f5e1b31e4377f0f1892d0e76d28a90e928cc2d6e189e1178934ad771aa
		  */
		let unhashed = try Data(hex: "5c210221090701070b0a5c1f0000000000000a661f0000000000000a991759bf467305d1220001b1035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f01000900e1f505080000210220220327038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c086c6f636b5f6665652007245c2101b50000e8890423c78a00000000000000000000000000000000000000000000000027038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c1277697468647261775f62795f616d6f756e742007405c2102b50000b0d86b9088a60000000000000000000000000000000000000000000000008200000000000000000000000000000000000000000000000000000027038108f45e17ae7960dce161b9f3c718e055191a909272995b4ff19d040c0d6465706f7369745f62617463682007055c2101a200202000")
		let hashed = Data(SHA256.twice(data: unhashed))
		XCTAssertEqual(hashed.hex, "c60e774c1e3c3a53df761eb336efc4c3a89f7265af305dcb2513113c7a44af7e")
		let publicKey = try K1.PublicKey.import(from: Data(hex: "035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f"))

		let signatureRaw = try ECDSASignatureRecoverable(rawRepresentation: Data(hex: "3901cf34cac6561eb9f1f68ff8bf84361ef005edd35f693e150046976c9d4a19aa71d74a9378119e186e2dcc28e9908ad2760e2d89f1f077431eb3e1f5c4bd0e01"))
		let signatureRadix = try ECDSASignatureRecoverable(radixFormat: Data(hex: "01194a9d6c974600153e695fd3ed05f01e3684bff88ff6f1b91e56c6ca34cf01390ebdc4f5e1b31e4377f0f1892d0e76d28a90e928cc2d6e189e1178934ad771aa"))

		let isValid = try publicKey.isValid(signature: signatureRadix, hashed: hashed)
		XCTAssertTrue(isValid)
	}

	func test_secp256k1_from_actual_sigs() throws {
		func doTest(
			pubkey pubkeyHex: String,
			unhashed unhashedHex: String,
			sigRadix: String,
			sigRaw: String,
			expHash: String
		) throws {
			let publicKey = try K1.PublicKey.import(from: Data(hex: pubkeyHex))
			let unhashed = try Data(hex: unhashedHex)

			let signatureRaw = try ECDSASignatureRecoverable(rawRepresentation: Data(hex: sigRaw))
			let signatureRadixFormat = try ECDSASignatureRecoverable(radixFormat: Data(hex: sigRadix))

			XCTAssertEqual(signatureRadixFormat.rawRepresentation.hex, signatureRaw.rawRepresentation.hex)
			XCTAssertEqual(signatureRadixFormat, signatureRaw)
			let hashed = Data(SHA256.twice(data: unhashed))
			XCTAssertEqual(hashed.hex, expHash)

			let isValid = try publicKey.isValid(signature: signatureRaw, hashed: hashed)
			if isValid {
				XCTAssertTrue(isValid) // awesome
			} else {
				let isValid2 = try publicKey.isValid(signature: signatureRadixFormat, hashed: hashed)
				XCTAssertTrue(isValid2)
				//                if isValid2 {
				//                    XCTAssertTrue(isValid2) // ok good, cool!
				//                } else {
				//                    let sig3 = try ECDSASignatureRecoverable(radixFormatVersion2: Data(hex: sigRadix))
				//                    let isValid3 = try publicKey.isValid(signature: sig3, unhashed: unhashed)
				//                    if isValid3 {
				//                        XCTAssertTrue(isValid3) // ok!
				//                    } else {
				//                        let sig4 = try ECDSASignatureRecoverable(radixFormatVersion2: Data(hex: sigRaw))
				//                        let isValid4 = try publicKey.isValid(signature: sig4, unhashed: unhashed)
				//                        XCTAssertTrue(isValid4)
				//                    }
				//                }
			}
		}

		try doTest(
			pubkey: "045e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f62b943b86ce5d179d830143e2ed2dee68e441c73cf935a5082fb59be252920dd",
			unhashed: "5c210221090701070b0a521f0000000000000a5c1f0000000000000a164d0278f152061e220001b1035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f01000900e1f505080000210220220327038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c086c6f636b5f6665652007245c2101b50000e8890423c78a00000000000000000000000000000000000000000000000027038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c1277697468647261775f62795f616d6f756e742007405c2102b500002cf61a24a2290000000000000000000000000000000000000000000000008200000000000000000000000000000000000000000000000000000027038108f45e17ae7960dce161b9f3c718e055191a909272995b4ff19d040c0d6465706f7369745f62617463682007055c2101a200202000",
			sigRadix: "0136be4965269c1166267793a776d92870879cede4fd0a56ca01a0d298a59d792c0d242a2fdba765c47d34c64048cd9f3ccf9e17180b2584a8bbec31e103ea0a8d",
			sigRaw: "2c799da598d2a001ca560afde4ed9c877028d976a793772666119c266549be368d0aea03e131ecbba884250b18179ecf3c9fcd4840c6347dc465a7db2f2a240d01",
			expHash: "a0bf59140aba45246c1cf6ddb5b4720b633ac6c7d057465c575a1cffe5c68d41"
		)
		/*
		 🔮 purpose=signers of intent, account: OlympiaSecp256k1, is signign data, using curve: secp256k1, derivationpath: m/44H/1022H/11H/618H/0H/1238H, from factor source id: FactorSourceID(hexCodable: 4bdea7577e1e1ffa34d7aa27dc4cc5b3c81c55086c112dcfe92e30e89ac7c3d0), factor source hint: olympia
		 🎉 secp256k1 signed hashed message: '78f929f648514ef42505ccefb7db1efeb214dd0d81e65d74c0da8d34ef59e57c'
		 publicKey: 045e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f62b943b86ce5d179d830143e2ed2dee68e441c73cf935a5082fb59be252920dd,
		 produced recoverable signature raw: 6256b586003df55fd35ee6a4dcd1e1a748accea99f3ef9d2bb82bb264d4905a94c27e43629c80eacd6e251b6331f24e09fb0a9469e9f5f0626e1b878e8f4692200,
		 sig.radixFormat: '00a905494d26bb82bbd2f93e9fa9ceac48a7e1d1dca4e65ed35ff53d0086b556622269f4e878b8e126065f9f9e46a9b09fe0241f33b651e2d6ac0ec82936e4274c'
		 ❌ purpose=signers of intent, bad! invalid secp256k1 sig
		 🎉factorInstance.publicKey=045e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f62b943b86ce5d179d830143e2ed2dee68e441c73cf935a5082fb59be252920dd🎉
		 ❌PubKey: 045e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f62b943b86ce5d179d830143e2ed2dee68e441c73cf935a5082fb59be252920dd❌
		 signature(radixformat):00a905494d26bb82bbd2f93e9fa9ceac48a7e1d1dca4e65ed35ff53d0086b556622269f4e878b8e126065f9f9e46a9b09fe0241f33b651e2d6ac0ec82936e4274c
		 signature(raw):6256b586003df55fd35ee6a4dcd1e1a748accea99f3ef9d2bb82bb264d4905a94c27e43629c80eacd6e251b6331f24e09fb0a9469e9f5f0626e1b878e8f4692200
		 unhashedData:5c210221090701070b0a551f0000000000000a5f1f0000000000000a2bfe8749cf86f913220001b1035e6355ef15c5b8eca46e47980a47abc84caaab1464708f3303d0c1b45f2f260f01000900e1f505080000210220220327038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c086c6f636b5f6665652007245c2101b50000e8890423c78a00000000000000000000000000000000000000000000000027038107d0bf143ad5849910bbe83546c5906bc22602d03fe2eabab5c2e70c1277697468647261775f62795f616d6f756e742007405c2102b500000c6d51c8f7aa0600000000000000000000000000000000000000000000008200000000000000000000000000000000000000000000000000000027038108f45e17ae7960dce161b9f3c718e055191a909272995b4ff19d040c0d6465706f7369745f62617463682007055c2101a200202000
		 */
	}
}
