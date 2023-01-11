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

public extension Curve25519.Signing.PrivateKey {
	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.publicKey == rhs.publicKey
	}
}

// MARK: - SLIP10.PrivateKey
public extension SLIP10 {
	enum PrivateKey: Sendable, Hashable {
		case curve25519(Curve25519.Signing.PrivateKey)
		case secp256k1(K1.PrivateKey)
	}
}

public extension SHA256 {
	/// SHA256 hashes `data` twice, as in `SHA256(SHA256(data))`
	static func twice(data: any DataProtocol) -> SHA256.Digest {
		SHA256.hash(data: Data(SHA256.hash(data: data)))
	}
}

public extension SLIP10.PrivateKey {
	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing, for secp256k1 we produce a
	/// recoverable ECDSA signature.
	func sign(
		data: any DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> SignatureWithPublicKey {
		try signReturningHashOfMessage(
			data: data,
			ifECDSASkipHashingBeforeSigning: ifECDSASkipHashingBeforeSigning
		).signatureWithPublicKey
	}

	/// Expects a non hashed `data`, will SHA256 double hash it for secp256k1,
	/// but not for Curve25519, before signing, for secp256k1 we produce a
	/// recoverable ECDSA signature.
	func signReturningHashOfMessage(
		data: any DataProtocol,
		ifECDSASkipHashingBeforeSigning: Bool = false
	) throws -> (signatureWithPublicKey: SignatureWithPublicKey, hashOfMessage: Data) {
		// We do Radix double SHA256 hashing, needed for secp256k1 but not for Curve25519, however,
		// the hash is used as Transaction Identifier, disregarding of Curveu used.
		let hashOfMessage = Data(SHA256.twice(data: data))

		switch self {
		case let .curve25519(key):
			// For Curve25519 we do not sign the hash but rather the original message,
			// but for secp256k1 we sign the hash.
			let signature = try key.signature(for: data)
			let publicKey = key.publicKey
			return (signatureWithPublicKey: SignatureWithPublicKey.eddsaEd25519(
				signature: signature,
				publicKey: publicKey
			), hashOfMessage: hashOfMessage)
		case let .secp256k1(key):
			// We do sign the hash of the message for secp256k1 but not for Curve25519.
			// Recoverable signature is needed
			let messageToSign = try {
				if ifECDSASkipHashingBeforeSigning {
					guard data.count == 32 else {
						throw SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong()
					}
					return data
				} else {
					return hashOfMessage
				}
			}()
			let signature = try key.ecdsaSignRecoverable(hashed: messageToSign)
			let publicKey = key.publicKey
			return (
				signatureWithPublicKey: SignatureWithPublicKey.ecdsaSecp256k1(
					signature: signature,
					publicKey: publicKey
				),
				hashOfMessage: hashOfMessage
			)
		}
	}
}

// MARK: - SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong
struct SpecifiedToSkipHashingBeforeSigningButInputDataIsNot32BytesLong: Swift.Error {}

public extension SLIP10.PrivateKey {
	func publicKey() -> SLIP10.PublicKey {
		switch self {
		case let .secp256k1(privateKey):
			return .ecdsaSecp256k1(privateKey.publicKey)
		case let .curve25519(privateKey):
			return .eddsaEd25519(privateKey.publicKey)
		}
	}
}

public extension SLIP10.PrivateKey {
	var rawRepresentation: Data {
		switch self {
		case let .secp256k1(privateKey):
			return privateKey.rawRepresentation
		case let .curve25519(privateKey):
			return privateKey.rawRepresentation
		}
	}

	var hex: String {
		rawRepresentation.hex
	}
}
