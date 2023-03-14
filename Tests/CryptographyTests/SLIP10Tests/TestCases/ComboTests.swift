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

	func test_secp256k1() throws {
		func doTest(
			pubkey pubkeyHex: String,
			unhashed unhashedHex: String,
			sigRadix: String,
			sigRaw: String,
			expHash: String
		) throws {
			let publicKey = try K1.PublicKey(rawRepresentation: Data(hex: pubkeyHex))
			let unhashed = try Data(hex: unhashedHex)

			let signatureRadixFormat = try ECDSASignatureRecoverable(radixFormat: Data(hex: sigRadix))
			let signatureRaw = try ECDSASignatureRecoverable(rawRepresentation: Data(hex: sigRaw))

			XCTAssertEqual(signatureRadixFormat.rawRepresentation.hex, signatureRaw.rawRepresentation.hex)
			XCTAssertEqual(signatureRadixFormat, signatureRaw)
			let hashed = SHA256.twice(data: unhashed)
			XCTAssertEqual(hashed.hex, expHash)

			let isValid = try publicKey.isValid(signature: signatureRadixFormat, unhashed: unhashed)

			XCTAssertTrue(isValid)
		}

		try doTest(pubkey: "", unhashed: "", sigRadix: "", sigRaw: "", expHash: "")
	}
}
