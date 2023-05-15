import Cryptography
import EngineToolkit
import TestingPrelude

final class ECDSASepc256k1RecoverableSignatureVerificationTests: TestCase {
	func test_serialize_ECDSA_signature() throws {
		let privateKey = try K1.PrivateKey(rawRepresentation: Data(hex: "0000000000000000000000000000000000000000000000000000000000000001"))
		let message0 = Data("Hello Radix".utf8)
		let signature0 = try privateKey.signature(forUnhashed: message0)
		try XCTAssertEqual(signature0.radixSerialize().hex, "001ff2b23b30d86edbd5a6b34f90f2d2d822fe27d13bd9a1ed7bd0417c8619815d73e93924f5f1cb0a32ef578fe4d82a21c7e81612c48f2617aebdb948166a2959")

		let message1 = Data("Hey Radix".utf8)
		let signature1 = try privateKey.signature(forUnhashed: message1)
		try XCTAssertEqual(signature1.radixSerialize().hex, "01c2bb0c7a7787d7a66fb5332d39b6d7ba49d4bd1d69fcc2ad3f5f70fe19676875462c59e9b9e0ff784797114b266e279646d1fd62a9af724a2666cdc498f9e3ff")
	}

	func test_secp256k1_new_key_validate_recoverable_signature() throws {
		let privateKey = K1.PrivateKey()
		let publicKey = privateKey.publicKey
		let unhashed = "Hey".data(using: .utf8)!
		let signature = try privateKey.signature(forUnhashed: unhashed)
		var isValid = false

		isValid = publicKey.isValidSignature(signature, unhashed: unhashed)
		XCTAssertTrue(isValid)

		let roundtripSig = try K1.ECDSAWithKeyRecovery.Signature(radixFormat: signature.radixSerialize())
		isValid = publicKey.isValidSignature(roundtripSig, unhashed: unhashed)
		XCTAssertTrue(isValid)
	}
}
