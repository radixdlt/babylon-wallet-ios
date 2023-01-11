import CryptoKit
import K1
import Prelude

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
