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
	public func sign(hashOfMessage: some DataProtocol) throws -> Engine.SignatureWithPublicKey {
		try SLIP10.PrivateKey(engine: self)
			.sign(hashOfMessage: hashOfMessage)
			.intoEngine()
	}
}
