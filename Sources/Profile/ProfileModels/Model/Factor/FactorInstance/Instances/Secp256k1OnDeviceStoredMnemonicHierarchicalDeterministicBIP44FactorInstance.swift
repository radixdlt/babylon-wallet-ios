import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance
/// An instance of a factor derived from some `Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource`
/// using `derivationPath` on the Elliptic Curve `Secp256k1` and BIP44 derivation scheme to produce the `publicKey`.
public struct Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance:
	FactorInstanceHierarchicalDeterministicSLIP10Protocol,
	FactorInstanceNonHardwareHierarchicalDeterministicProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	public let factorSourceReference: FactorSourceReference
	public let publicKey: SLIP10.PublicKey
	public let initializationDate: Date
	public let derivationPath: DerivationPath
	public let factorInstanceID: FactorInstanceID

	public init(
		factorSourceReference: FactorSourceReference,
		publicKey: SLIP10.PublicKey,
		derivationPath: DerivationPath,
		initializationDate: Date = .init()
	) {
		self.factorSourceReference = factorSourceReference
		self.publicKey = publicKey
		self.factorInstanceID = SHA256.factorInstanceID(publicKey: publicKey)
		self.derivationPath = derivationPath
		self.initializationDate = initializationDate.stableEquatableAfterJSONRoundtrip
	}
}

extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance {
	public static let factorInstanceKind: FactorInstanceKind = .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstanceKind
	public typealias Curve = SECP256K1
	public typealias ID = FactorSourceReference
}

extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance {
	/// Wraps this `Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance` into the shared
	/// nominal type `FactorInstance` (enum)
	public func wrapAsFactorInstance() -> FactorInstance {
		.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(self)
	}

	/// Tries to unwraps the nominal type `FactorInstance` (enum)
	/// into a `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance` instance.
	public static func unwrap(factorInstance: FactorInstance) -> Self? {
		switch factorInstance {
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance(instance):
			return instance
		default:
			return nil
		}
	}
}

extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance {
	public var customDumpMirror: Mirror {
		.init(self, children: [
			"factorSourceReference": factorSourceReference,
			"publicKey": publicKey,
			"initializationDate": initializationDate,
			"derivationPath": derivationPath,
		])
	}

	public var description: String {
		"""
		"factorSourceReference": \(factorSourceReference),
		"publicKey": \(publicKey),
		"initializationDate": \(initializationDate),
		"derivationPath": \(derivationPath)
		"""
	}
}
