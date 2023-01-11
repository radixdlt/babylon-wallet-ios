import CustomDump
import Foundation

// MARK: - FactorSource
/// Shared nominal type for all factor sources.
public enum FactorSource:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	/// A Hierarchical Deterministic factor source based on a BIP39 Mnemonic that is stored on the device,
	/// for factor instances based on `Curve25519` keys derived using SLIP10.
	case curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource)

	/// A Hierarchical Deterministic factor source based on a BIP39 Mnemonic that is stored on the device,
	/// for factor instances based on `Curve25519` keys derived using BIP44.
	case secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource)
}

public extension FactorSource {
	func any() -> any FactorSourceProtocol {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(source):
			return source
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(source):
			return source
		}
	}
}

public extension FactorSource {
	var customDumpDescription: String {
		_description
	}

	var description: String {
		_description
	}

	var _description: String {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(source):
			return "Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(\(source)"
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(source):
			return "Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(\(source)"
		}
	}
}
