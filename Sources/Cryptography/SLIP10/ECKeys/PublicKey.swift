import CryptoKit
import CustomDump
import Foundation
import K1

// MARK: - SLIP10.PublicKey
extension SLIP10 {
	public enum PublicKey: Sendable, Hashable {
		case ecdsaSecp256k1(K1.PublicKey)
		case eddsaEd25519(Curve25519.Signing.PublicKey)

		public init(data: Data) throws {
			do {
				self = try .eddsaEd25519(.init(compressedRepresentation: data))
			} catch {
				self = try .ecdsaSecp256k1(.init(compressedRepresentation: data))
			}
		}
	}
}

extension SLIP10.PublicKey {
	public func isValidSignature(
		_ signatureWrapper: SLIP10.Signature,
		hashed: some DataProtocol
	) -> Bool {
		switch (signatureWrapper, self) {
		case let (.ecdsaSecp256k1(ecdsaSecp256k1Signature), .ecdsaSecp256k1(ecdsaSecp256k1PublicKey)):

			do {
				return try ecdsaSecp256k1PublicKey.isValid(signature: ecdsaSecp256k1Signature, hashed: hashed)
			} catch {
				return false
			}

		case (.ecdsaSecp256k1, .eddsaEd25519):
			return false

		case (.eddsaEd25519, .ecdsaSecp256k1):
			return false

		case let (.eddsaEd25519(eddsaEd25519Signature), .eddsaEd25519(eddsaEd25519PublicKey)):
			return eddsaEd25519PublicKey.isValidSignature(eddsaEd25519Signature, for: hashed)
		}
	}
}

// MARK: - SLIP10.PublicKey + CustomDebugStringConvertible, CustomDumpStringConvertible, CustomStringConvertible
extension SLIP10.PublicKey: CustomDebugStringConvertible, CustomDumpStringConvertible, CustomStringConvertible {
	/// For ECDSA secp256k1 public keys this will use the compressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	public var compressedRepresentation: Data {
		switch self {
		case let .eddsaEd25519(publicKey):
			return publicKey.compressedRepresentation
		case let .ecdsaSecp256k1(publicKey):
			return publicKey.compressedRepresentation
		}
	}

	/// For ECDSA secp256k1 public keys this will use the uncompressed representation
	/// For EdDSA Curve25519 there is no difference between compressed and uncompressed.
	public var uncompressedRepresentation: Data {
		switch self {
		case let .eddsaEd25519(publicKey):
			return publicKey.rawRepresentation
		case let .ecdsaSecp256k1(publicKey):
			return try! Data(publicKey.rawRepresentation(format: .uncompressed))
		}
	}

	public var debugDescription: String {
		switch self {
		case let .eddsaEd25519(key):
			return "Curve25519(\(key.compressedRepresentation.hex))"
		case let .ecdsaSecp256k1(key):
			return "K1(\(key.compressedRepresentation.hex))"
		}
	}

	public var description: String {
		debugDescription
	}

	public var customDumpDescription: String {
		debugDescription
	}
}
