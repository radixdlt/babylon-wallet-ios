import Cryptography
import EngineToolkit
import TestingPrelude

final class ECDSASepc256k1RecoverableSignatureVerificationTests: TestCase {
	func test_serialize_ECDSA_signature() throws {
		let privateKey = try K1.PrivateKey(rawRepresentation: Data(hex: "0000000000000000000000000000000000000000000000000000000000000001"))
		let message0 = Data("Hello Radix".utf8)
		let signature0 = try privateKey.ecdsaSignRecoverable(unhashed: message0)
		try XCTAssertEqual(signature0.radixSerialize().hex, "001ff2b23b30d86edbd5a6b34f90f2d2d822fe27d13bd9a1ed7bd0417c8619815d73e93924f5f1cb0a32ef578fe4d82a21c7e81612c48f2617aebdb948166a2959")

		let message1 = Data("Hey Radix".utf8)
		let signature1 = try privateKey.ecdsaSignRecoverable(unhashed: message1)
		try XCTAssertEqual(signature1.radixSerialize().hex, "01c2bb0c7a7787d7a66fb5332d39b6d7ba49d4bd1d69fcc2ad3f5f70fe19676875462c59e9b9e0ff784797114b266e279646d1fd62a9af724a2666cdc498f9e3ff")
	}

	func test_signature_format_conversion() throws {
		let rawHex = "2c799da598d2a001ca560afde4ed9c877028d976a793772666119c266549be368d0aea03e131ecbba884250b18179ecf3c9fcd4840c6347dc465a7db2f2a240d01"
		let raw = try Data(hex: rawHex)
		let signatureRaw = try ECDSASignatureRecoverable(rawRepresentation: raw)
		try XCTAssertEqual(signatureRaw.radixSerialize().hex, "0136be4965269c1166267793a776d92870879cede4fd0a56ca01a0d298a59d792c0d242a2fdba765c47d34c64048cd9f3ccf9e17180b2584a8bbec31e103ea0a8d")
		let fromRadixFormat = try ECDSASignatureRecoverable(radixFormat: "0136be4965269c1166267793a776d92870879cede4fd0a56ca01a0d298a59d792c0d242a2fdba765c47d34c64048cd9f3ccf9e17180b2584a8bbec31e103ea0a8d")
		XCTAssertEqual(fromRadixFormat.rawRepresentation.hex, rawHex)
	}

	func test_secp256k1_new_key_validate_recoverable_signature() throws {
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
}
