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

extension SHA256 {
	/// SHA256 hashes `data` twice, as in `SHA256(SHA256(data))`
	public static func twice(data: some DataProtocol) -> SHA256.Digest {
		SHA256.hash(data: Data(SHA256.hash(data: data)))
	}
}

extension SLIP10.PrivateKey {
	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing, for secp256k1 we produce a
	/// recoverable ECDSA signature.
	public func sign(
		unhashed: some DataProtocol,
		hashOfMessage: some DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> SignatureWithPublicKey {
		try signReturningHashOfMessage(
			unhashed: unhashed,
			hashOfMessage: hashOfMessage,
			ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning
		).signatureWithPublicKey
	}

	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing, for secp256k1 we produce a
	/// recoverable ECDSA signature.
	public func signReturningHashOfMessage(
		unhashed unhashed_: some DataProtocol,
		hashOfMessage hashOfMessage_: some DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> (signatureWithPublicKey: SignatureWithPublicKey, hashOfMessage: Data) {
		// TODO: Update this comment:
		// We do Radix double SHA256 hashing, needed for secp256k1 but not for Curve25519, however,
		// the hash is used as Transaction Identifier, disregarding of Curveu used.
		let unhashed = Data(unhashed_)
		let hashOfMessage = Data(hashOfMessage_)

		// We now sign the hash of the message for both secp256k1 and Curve25519.
		switch self {
		case let .curve25519(key):
			let signature = try key.signature(for: hashOfMessage)
			let publicKey = key.publicKey
			let isValid = publicKey.isValidSignature(signature, for: hashOfMessage)
			guard isValid else {
				throw Curve25519SignatureJustProducedIsInvalid()
			}
			return (signatureWithPublicKey: SignatureWithPublicKey.eddsaEd25519(
				signature: signature,
				publicKey: publicKey
			), hashOfMessage: hashOfMessage)

		case let .secp256k1(key):
			// Recoverable signature is needed
			let messageToSign = try {
				if ifECDSASkipHashingBeforeSigning {
					guard unhashed.count == 32 else {
						throw SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong()
					}
					return unhashed
				} else {
					return hashOfMessage
				}
			}()
			let signature = try key.ecdsaSignRecoverable(hashed: messageToSign)
			let publicKey = key.publicKey

			let isValid = try publicKey.isValid(
				signature: signature,
				hashed: messageToSign
			)

			guard isValid else {
				throw Secp256k1SignatureJustProducedIsInvalid()
			}

			let signatureWithPublicKey = SignatureWithPublicKey.ecdsaSecp256k1(
				signature: signature,
				publicKey: publicKey
			)
			return (
				signatureWithPublicKey,
				hashOfMessage
			)
		}
	}
}

// MARK: - SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong
struct SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong: Swift.Error {}

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
