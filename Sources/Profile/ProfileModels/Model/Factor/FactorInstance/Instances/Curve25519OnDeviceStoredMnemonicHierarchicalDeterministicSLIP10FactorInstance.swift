import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance
/// An instance of a factor derived from some `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource`
/// using `derivationPath` on the Elliptic Curve `Curve25519` and SLIP10 derivation scheme to produce the `publicKey`.
public struct Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance:
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

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance {
	public static let factorInstanceKind: FactorInstanceKind = .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstanceKind

	public typealias Curve = Curve25519
	public typealias ID = FactorSourceReference
}

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance {
	/// Wraps this `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance` into the shared
	/// nominal type `FactorInstance` (enum)
	public func wrapAsFactorInstance() -> FactorInstance {
		.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(self)
	}

	/// Tries to unwraps the nominal type `FactorInstance` (enum)
	/// into a `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance` instance.
	public static func unwrap(factorInstance: FactorInstance) -> Self? {
		switch factorInstance {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(instance):
			return instance
		default:
			return nil
		}
	}
}

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance {
	public var customDumpMirror: Mirror {
		.init(self, children: [
			"factorSourceReference": factorSourceReference,
			"publicKey": publicKey.compressedData.hex(),
			"initializationDate": initializationDate,
			"derivationPath": derivationPath,
		])
	}

	public var description: String {
		"""
		"factorSourceReference": \(factorSourceReference),
		"publicKey": \(publicKey.compressedData.hex()),
		"initializationDate": \(initializationDate),
		"derivationPath": \(derivationPath),
		"""
	}
}
