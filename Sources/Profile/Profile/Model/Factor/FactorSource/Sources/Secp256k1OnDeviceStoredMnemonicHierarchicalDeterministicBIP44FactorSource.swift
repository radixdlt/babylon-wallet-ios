import CryptoKit
import CustomDump
import EngineToolkit
import Foundation
import Mnemonic
import SLIP10

// MARK: - Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource
/// A Hierarchical Deterministic factor source based on a BIP39 Mnemonic that is stored on the device,
/// for factor instances based on `Secp256k1` keys derived using BIP44.
///
/// This factor source is often referred to as the `OlympiaFactorSource` or `LegacyFactorSource`,
/// since Radix `Olympia` milestone used Secp256k1 and BIP44.
public struct Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource:
	OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource, // BIP44 is compatible with SLIP10 for `secp256k1`
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// `SHA256(SHA256(masterPublicKey.compressedForm)`
	public let factorSourceID: FactorSourceID

	/// When this factor source was created.
	public let creationDate: Date

	/// An optional label of this factor source.
	public let label: String?

	public init(
		factorSourceID: FactorSourceID,
		label: String? = "OlympiaFactorSource",
		creationDate: Date = .init()
	) {
		self.factorSourceID = factorSourceID
		self.label = label
		self.creationDate = creationDate.stableEquatableAfterJSONRoundtrip
	}

	public init(
		mnemonic: Mnemonic,
		bip39Passphrase: String = "",
		label: String? = "OlympiaFactorSource",
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

public extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource {
	/// Wraps this specific type of factor source to the shared
	/// nominal type `FactorSource` (enum)
	func wrapAsFactorSource() -> FactorSource {
		.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(self)
	}

	/// Tries to unwraps the nominal type `FactorSource` (enum)
	/// into this specific type.
	static func unwrap(factorSource: FactorSource) -> Self? {
		switch factorSource {
		case let .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource(source):
			return source
		default:
			return nil
		}
	}

	static func embedPrivateKey(_ privateKey: Self.Curve.PrivateKey) -> PrivateKey {
		.secp256k1(privateKey)
	}

	static func embedPublicKey(_ publicKey: Self.Curve.PublicKey) -> PublicKey {
		.ecdsaSecp256k1(publicKey)
	}
}

public extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource {
	static let factorSourceKind: FactorSourceKind = .secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSourceKind

	typealias Instance = Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorInstance
	typealias CreateFactorInstanceInput = CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput
	typealias Curve = SECP256K1
}

public extension Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource {
	var customDumpMirror: Mirror {
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

	var description: String {
		"""
		id: \(id),
		creationDate: \(creationDate.ISO8601Format()),
		label: \(String(describing: label))
		"""
	}
}
