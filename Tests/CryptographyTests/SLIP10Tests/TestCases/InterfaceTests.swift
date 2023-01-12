@testable import Cryptography
import TestingPrelude

// MARK: - InterfaceTests
final class InterfaceTests: XCTestCase {
	func testSlip10() throws {
		let insecureSeed = "insecure seed of at least 128 bit".data(using: .utf8)!
		let root = try HD.Root(seed: insecureSeed)
		let path = try HD.Path.Full(string: "m/1022'/0'/0'/0'/0'")
		let extendedKey = try root.derivePrivateKey(path: path, curve: Curve25519.self)
		XCTAssertEqual(extendedKey.derivationPath, .full(path))

		let messageToHashAndSign = "Hello World!".data(using: .utf8)!
		let signature = try extendedKey.privateKey!.signature(for: messageToHashAndSign)
		XCTAssertTrue(extendedKey.publicKey.isValidSignature(signature, for: messageToHashAndSign))

		XCTAssertEqual(try extendedKey.xpub(),
		               "xpub6G29mZKKVXdqcEYLaAUxdGPMGAvXbwXXxUpJSDLFEJh6rRWnUb7HdDDLDzaD2zkCiu1P4GP4R6y7P7zos8HfQNy1iKopzApn5a7HFjKHzUb")
		XCTAssertEqual(try extendedKey.xprv(),
		               "xprvA32oN3nRfA5YPkTsU8wxG8Sci963CUogbFthdpvdfyA7ydBdw3o35QtrNnaM6G5kBU2mwFbNPBPsB7Am3g3Zi6bm3YXvDnDXtihS3yUvAgo")
		XCTAssertEqual(extendedKey.chainCode.chainCode.hex(), "67645a3e13ea63de86742415470489e343a0267b5864f77f2db909efd4616e70")
		XCTAssertEqual(extendedKey.fingerprint.fingerprint.hex(), "525ce405")

		let childPublicKey = try extendedKey.derivePublicKey(path: .harden(1))
		XCTAssertEqual(childPublicKey.derivationPath, try HD.Path(string: "m/1022'/0'/0'/0'/0'/1'"))
		XCTAssertThrowsError(try childPublicKey.xprv())
		XCTAssertEqual(try childPublicKey.xpub(), "xpub6HJnDxL4npVUAFLjb6gxZQqCqVJbYKn5E22fQADcT2LvYHZzFAiFW4hTuQjaRsUrF28EQGsCynUz1pP7sqQ23MWdph3XxHNGuWue5BqCgmx")

		let childPrivateKey = try extendedKey.derivePrivateKey(path: .harden(1))
		XCTAssertEqual(childPublicKey.derivationPath, childPrivateKey.derivationPath)
		XCTAssertEqual(try childPublicKey.xpub(), try childPrivateKey.xpub())

		XCTAssertEqual(try childPrivateKey.xprv(), "xprvA4KRpSoAxSwAwmGGV59xCGtUHTU78s4Dro74bmoztgowfVEqhdPzxGNz4DHhLfZTjvEvsqSSJofA42gHTcPfQhzhxDnbg1fLa7Q6exF9dNh")
	}
}

public extension HD.Path.Relative {
	static func harden(_ value: HierarchicalDeterministic.Path.Component.Child.Value) throws -> Self {
		try .init(components: [.harden(value)])
	}
}

public extension HD.Path.Component {
	static func harden(_ value: HierarchicalDeterministic.Path.Component.Child.Value) -> Self {
		.child(.harden(value))
	}
}
