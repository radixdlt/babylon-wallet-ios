import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
/// A Hierarchical Deterministic factor source based on a BIP39 Mnemonic that is stored on the device,
/// for factor instances based on `Curve25519` keys derived using SLIP10.
///
/// This factor source is often referred to as the `DeviceFactorSource`.
public struct Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource:
	OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// `SHA256(SHA256(masterPublicKey.compressedForm)`
	public let factorSourceID: FactorSourceID
	public var supportsHierarchicalDeterministicDerivation: Bool { true }

	/// When this factor source was created.
	public let creationDate: Date

	/// An optional label of this factor source.
	public let label: String?

	public init(
		factorSourceID: FactorSourceID,
		label: String? = "DeviceFactorSource",
		creationDate: Date = .init()
	) {
		self.factorSourceID = factorSourceID
		self.label = label
		self.creationDate = creationDate.stableEquatableAfterJSONRoundtrip
	}

	public init(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		label: String? = "DeviceFactorSource",
		creationDate: Date = .init()
	) throws {
		try self.init(
			factorSourceID: HD.Root(
				seed: mnemonic.seed(passphrase: bip39Passphrase)
			)
			.factorSourceID(
				curve: Curve.self
			),
			label: label,
			creationDate: creationDate
		)
	}
}

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	/// Wraps this specific type of factor source to the shared
	/// nominal type `FactorSource` (enum)
	public func wrapAsFactorSource() -> FactorSource {
		.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(self)
	}

	/// Tries to unwraps the nominal type `FactorSource` (enum)
	/// into this specific type.
	public static func unwrap(factorSource: FactorSource) -> Self? {
		switch factorSource {
		case let .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource(source):
			return source
		default:
			return nil
		}
	}

	public static func embedPrivateKey(_ privateKey: Self.Curve.PrivateKey) -> SLIP10.PrivateKey {
		.curve25519(privateKey)
	}

	public static func embedPublicKey(_ publicKey: Self.Curve.PublicKey) -> SLIP10.PublicKey {
		.eddsaEd25519(publicKey)
	}
}

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	public static let factorSourceKind: FactorSourceKind = .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind

	public typealias Instance = Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance
	public typealias CreateFactorInstanceInput = CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	public typealias Curve = Curve25519
}

extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"id": factorSourceID.rawValue,
				"creationDate": creationDate.ISO8601Format(),
				"label": String(describing: label),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		id: \(id),
		creationDate: \(creationDate.ISO8601Format()),
		label: \(String(describing: label))
		"""
	}
}

#if DEBUG
extension Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource {
	public static let previewValue: Self = try! .init(mnemonic: .generate())
}
#endif // DEBUG
