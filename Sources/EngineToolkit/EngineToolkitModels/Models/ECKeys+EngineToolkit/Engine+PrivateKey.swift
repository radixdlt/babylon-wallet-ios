import Cryptography
import Prelude

// MARK: - Engine.PrivateKey
public extension Engine {
	enum PrivateKey {
		case curve25519(Curve25519.Signing.PrivateKey)
		case secp256k1(K1.PrivateKey)
	}
}

public extension Engine.PrivateKey {
	func publicKey() throws -> Engine.PublicKey {
		try SLIP10.PrivateKey(engine: self)
			.publicKey()
			.intoEngine()
	}
}

public extension Engine.PrivateKey {
	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing.
	func sign(
		data: any DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> Engine.SignatureWithPublicKey {
		try signReturningHashOfMessage(data: data, ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning).signatureWithPublicKey
	}

	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing.
	func signReturningHashOfMessage(
		data: any DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> (signatureWithPublicKey: Engine.SignatureWithPublicKey, hashOfMessage: Data) {
		let signatureAndMessage = try SLIP10.PrivateKey(engine: self).signReturningHashOfMessage(
			data: data,
			ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning
		)
		var signatureWithPublicKey = try signatureAndMessage.signatureWithPublicKey.intoEngine()

		// TODO: Remove when a fix is implemented at the K1 side.

		// The following is a temporary fix for the ECDSA signatures to allow them to be put in a format that is
		// expected. Currently, K1 returns a bytearray of (reverded(r) + reversed(s) + [v]) which Scrypto does not
		// expect. Therefore, the following code modifies the above-mentioned format to be ([v] + r + s).
		// Note: Correction is only needed for Ecdsa Secp256k1 and not Eddsa Ed25519
		switch signatureWithPublicKey {
		case let .ecdsaSecp256k1(ecdsaSignature):
			let signatureBytes = ecdsaSignature.bytes

			let r = signatureBytes[0 ..< 32].reversed()
			let s = signatureBytes[32 ..< 64].reversed()
			let v = signatureBytes[64]

			signatureWithPublicKey = .ecdsaSecp256k1(signature: Engine.EcdsaSecp256k1Signature(bytes: [v] + r + s))
		default:
			break
		}

		return (
			signatureWithPublicKey: signatureWithPublicKey,
			hashOfMessage: signatureAndMessage.hashOfMessage
		)
	}
}
