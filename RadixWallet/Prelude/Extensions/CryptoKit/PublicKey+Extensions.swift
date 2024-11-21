
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

// MARK: - Data + @unchecked Sendable
extension Data: @unchecked Sendable {}
typealias EdDSASignature = Data

// MARK: - Curve25519.Signing.PublicKey + @unchecked Sendable
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

// MARK: - Curve25519.Signing.PrivateKey + @unchecked Sendable
extension Curve25519.Signing.PrivateKey: @unchecked Sendable {}

// MARK: - Curve25519.Signing.PrivateKey + Hashable
extension Curve25519.Signing.PrivateKey: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.publicKey)
	}
}

// MARK: - Curve25519.Signing.PrivateKey + Equatable
extension Curve25519.Signing.PrivateKey: Equatable {}
extension Curve25519.Signing.PrivateKey {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.publicKey == rhs.publicKey
	}
}

extension Curve25519 {
	typealias PrivateKey = Curve25519.Signing.PrivateKey
	typealias PublicKey = Curve25519.Signing.PublicKey
}

// MARK: - Curve25519.Signing.PublicKey + ECPublicKey
extension Curve25519.Signing.PublicKey {
	init(compressedRepresentation: some ContiguousBytes) throws {
		// Curve25519 keys ARE always compressed.
		try self.init(rawRepresentation: compressedRepresentation)
	}

	var compressedRepresentation: Data {
		// Curve25519 keys ARE always compressed.
		rawRepresentation
	}
}
