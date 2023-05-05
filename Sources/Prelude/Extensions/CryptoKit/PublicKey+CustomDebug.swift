import CryptoKit
import CustomDump

// MARK: - Curve25519.Signing.PublicKey + CustomDumpStringConvertible
extension Curve25519.Signing.PublicKey: CustomDumpStringConvertible, CustomDebugStringConvertible {
	public var customDumpDescription: String {
		debugDescription
	}

	public var debugDescription: String {
		rawRepresentation.hex
	}
}
