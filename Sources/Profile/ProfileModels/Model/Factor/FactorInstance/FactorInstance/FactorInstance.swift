import Cryptography
import Prelude

// MARK: - FactorInstance
/// Shared nominal type for all factor instances.
public enum FactorInstance:
	Sendable,
	Hashable,
	Codable,
	CustomDumpStringConvertible
{
	/// An instance of a factor derived from some `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource`.
	case curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance)

	/// An instance of a factor derived from some `Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource`.
	case secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance)
}

public extension FactorInstance {
	func any() -> any FactorInstanceProtocol {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(instance):
			return instance
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(instance):
			return instance
		}
	}

	var factorInstanceKind: FactorInstanceKind {
		property(\.factorInstanceKind)
	}

	var factorSourceReference: FactorSourceReference {
		property(\.factorSourceReference)
	}

	var initializationDate: Date {
		property(\.initializationDate)
	}

	var factorInstanceID: FactorInstanceID {
		property(\.factorInstanceID)
	}

	// uhm, not pretty, but this is highly temporary, gonna be rewritten before March 2023.
	var publicKey: SLIP10.PublicKey {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(fi):
			return fi.publicKey
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(fi):
			return fi.publicKey
		}
	}

	internal func property<Property>(_ keyPath: KeyPath<FactorInstanceProtocol, Property>) -> Property {
		any()[keyPath: keyPath]
	}

	var curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance: Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance? {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(instance):
			return instance
		default:
			return nil
		}
	}
}

public extension FactorInstance {
	var customDumpDescription: String {
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(factorInstance):
			return "\(String(describing: factorInstance))"
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(factorInstance):
			return "\(String(describing: factorInstance))"
		}
	}
}

public extension FactorInstance {
	enum CodingKeys: String, CodingKey {
		case factorSourceReference
	}

	init(from decoder: Decoder) throws {
		// This is slightly "hacky", what we do is that we rely on the fact that each FactorInstance
		// conform to FactorInstanceProtocol which requires a non-static stored (JSON encoded)
		// property named `factorSourceReference` of type `FactorSourceReference`, which contains the
		// `factorSourceKind: FactorSourceKind` property, which we can use to get FactorSourceKind which
		// MUST map 1:1 to a FactorInstanceKind which has a property `sourceOfInstanceOfKind: FactorInstanceKind`
		// which we use as a discriminator.
		let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
		let factorSourceReference = try keyedContainer.decode(FactorSourceReference.self, forKey: .factorSourceReference)

		let container = try decoder.singleValueContainer()
		switch factorSourceReference.factorSourceKind.sourceOfInstanceOfKind {
		case .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstanceKind:
			self = try .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(container.decode(Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance.self))
		case .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstanceKind:
			self = try .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(container.decode(Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance.self))
		}
	}

	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		switch self {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(instance):
			try singleValueContainer.encode(instance)
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(instance):
			try singleValueContainer.encode(instance)
		}
	}
}
