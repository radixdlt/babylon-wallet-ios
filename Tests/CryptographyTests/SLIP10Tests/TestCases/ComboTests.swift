@testable import Cryptography
import CryptoKit
import XCTest

public extension HD.Root {
	init(mnemonic: Mnemonic, passphrase: String = "") throws {
		try self.init(seed: mnemonic.seed(passphrase: passphrase))
	}
}

// MARK: - ComboTests
final class ComboTests: XCTestCase {
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
}
