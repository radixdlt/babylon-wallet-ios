import CustomDump
import Foundation

/// A kind of factor instance.
public enum FactorInstanceKind:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	/// A factor instance created from a `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource` factor source.
	case curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstanceKind

	/// A factor instance created from a `Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource` factor source.
	case secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstanceKind
}
