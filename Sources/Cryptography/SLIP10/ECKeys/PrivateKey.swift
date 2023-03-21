import CryptoKit
import Foundation
import K1

// MARK: - Curve25519.Signing.PrivateKey + Sendable
extension Curve25519.Signing.PrivateKey: @unchecked Sendable {}

// MARK: - Curve25519.Signing.PrivateKey + Hashable
extension Curve25519.Signing.PrivateKey: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.publicKey)
	}
}

extension Curve25519.Signing.PrivateKey {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.publicKey == rhs.publicKey
	}
}

// MARK: - SLIP10.PrivateKey
extension SLIP10 {
	public enum PrivateKey: Sendable, Hashable {
		case curve25519(Curve25519.Signing.PrivateKey)
		case secp256k1(K1.PrivateKey)
	}
}

extension SLIP10.PrivateKey {
	/// For secp256k1 we produce a recoverable ECDSA signature.
	public func sign(hashOfMessage: some DataProtocol) throws -> SignatureWithPublicKey {
		// We now sign the hash of the message for both secp256k1 and Curve25519.
		switch self {
		case let .curve25519(key):
			let signature = try key.signature(for: hashOfMessage)
			let publicKey = key.publicKey
			let isValid = publicKey.isValidSignature(signature, for: hashOfMessage)
			guard isValid else {
				throw Curve25519SignatureJustProducedIsInvalid()
			}
			return .eddsaEd25519(
				signature: signature,
				publicKey: publicKey
			)

		case let .secp256k1(key):
			// Recoverable signature is needed
			let signature = try key.ecdsaSignRecoverable(hashed: hashOfMessage)
			let publicKey = key.publicKey

			let isValid = try publicKey.isValid(
				signature: signature,
				hashed: hashOfMessage
			)

			guard isValid else {
				throw Secp256k1SignatureJustProducedIsInvalid()
			}

			return .ecdsaSecp256k1(
				signature: signature,
				publicKey: publicKey
			)
		}
	}
}

// MARK: - Secp256k1SignatureJustProducedIsInvalid
struct Secp256k1SignatureJustProducedIsInvalid: Swift.Error {}

// MARK: - Curve25519SignatureJustProducedIsInvalid
struct Curve25519SignatureJustProducedIsInvalid: Swift.Error {}

extension SLIP10.PrivateKey {
	public func publicKey() -> SLIP10.PublicKey {
		switch self {
		case let .secp256k1(privateKey):
			return .ecdsaSecp256k1(privateKey.publicKey)
		case let .curve25519(privateKey):
			return .eddsaEd25519(privateKey.publicKey)
		}
	}
}

extension SLIP10.PrivateKey {
	public var rawRepresentation: Data {
		switch self {
		case let .secp256k1(privateKey):
			return privateKey.rawRepresentation
		case let .curve25519(privateKey):
			return privateKey.rawRepresentation
		}
	}

	public var hex: String {
		rawRepresentation.hex
	}
}
