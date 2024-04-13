
import CryptoKit

// MARK: - Curve25519.Signing.PublicKey + CustomDumpStringConvertible, CustomDebugStringConvertible
extension Curve25519.Signing.PublicKey: CustomDumpStringConvertible, CustomDebugStringConvertible {
	public var customDumpDescription: String {
		debugDescription
	}

	public var debugDescription: String {
		rawRepresentation.hex
	}
}

// MARK: - Data + Sendable
extension Data: @unchecked Sendable {}
public typealias EdDSASignature = Data

// MARK: - Curve25519.Signing.PublicKey + Sendable
extension Curve25519.Signing.PublicKey: @unchecked Sendable {}

// MARK: - Curve25519.Signing.PublicKey + Hashable
extension Curve25519.Signing.PublicKey: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.rawRepresentation)
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		safeCompare(lhs.rawRepresentation, rhs.rawRepresentation)
	}
}

extension Curve25519.Signing.PrivateKey {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.publicKey == rhs.publicKey
	}
}

extension Curve25519 {
	public typealias PrivateKey = Curve25519.Signing.PrivateKey
	public typealias PublicKey = Curve25519.Signing.PublicKey
}

// MARK: - Curve25519.Signing.PublicKey + ECPublicKey
extension Curve25519.Signing.PublicKey {
	public init(compressedRepresentation: some ContiguousBytes) throws {
		// Curve25519 public keys ARE always compressed.
		try self.init(rawRepresentation: compressedRepresentation)
	}

	public var compressedRepresentation: Data {
		// Curve25519 public keys ARE always compressed.
		rawRepresentation
	}
}
