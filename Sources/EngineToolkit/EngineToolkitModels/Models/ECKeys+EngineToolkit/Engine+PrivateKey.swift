import Cryptography
import Prelude

// MARK: - Engine.PrivateKey
extension Engine {
	public enum PrivateKey {
		case curve25519(Curve25519.Signing.PrivateKey)
		case secp256k1(K1.PrivateKey)
	}
}

extension Engine.PrivateKey {
	public func publicKey() throws -> Engine.PublicKey {
		try SLIP10.PrivateKey(engine: self)
			.publicKey()
			.intoEngine()
	}
}

extension Engine.PrivateKey {
	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing.
	public func sign(
		unhashed: some DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> Engine.SignatureWithPublicKey {
		try signReturningHashOfMessage(
			unhashed: unhashed,
			ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning
		)
		.signatureWithPublicKey
	}

	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing.
	public func signReturningHashOfMessage(
		unhashed: some DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> (signatureWithPublicKey: Engine.SignatureWithPublicKey, hashOfMessage: Data) {
		let signatureAndMessage = try SLIP10.PrivateKey(engine: self).signReturningHashOfMessage(
			unhashed: unhashed,
			ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning
		)
		let signatureWithPublicKey = try signatureAndMessage.signatureWithPublicKey.intoEngine()
		return (
			signatureWithPublicKey: signatureWithPublicKey,
			hashOfMessage: signatureAndMessage.hashOfMessage
		)
	}
}
