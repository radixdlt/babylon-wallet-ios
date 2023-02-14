import Prelude

// MARK: - FactorSourceKind
/// A kind of factor source.
public enum FactorSourceKind:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CaseIterable,
	CustomDumpRepresentable
{
	/// A factor source for factor instances using the `Curve25519`, `SLIP10` and derivation with
	/// a mnemonic that is stored on the device.
	case curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind

	/// A factor source for factor instances using the `Secp256k1`, `BIP44` and derivation with
	/// a mnemonic that is stored on the device.
	case secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSourceKind
}

extension FactorSourceKind {
	public var sourceOfInstanceOfKind: FactorInstanceKind {
		switch self {
		case .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind:
			return .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstanceKind
		case .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSourceKind:
			return .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstanceKind
		}
	}
}
