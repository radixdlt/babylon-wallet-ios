import Prelude

// MARK: - FactorSources
/// All the FactorSources the user have added.
public struct FactorSources:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// A non empty ordered set of `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource` factor sources.
	public var curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources: NonEmpty<OrderedSet<Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource>>

	/// An ordered set of  `Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource` factor sources.
	public var secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources: OrderedSet<Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource>

	public init(
		curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources: NonEmpty<OrderedSet<Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource>>,
		secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources: OrderedSet<Secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSource> = .init()
	) {
		self.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources = curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources
		self.secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources = secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources
	}
}

public extension FactorSources {
	/// When the wallet notarized transactions it should be able to do that without the input from the user (except auth with Biometrics...)
	/// thus we use the "OnDeviceFactorSource" which is the `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource`
	/// as factor source for notary private key.
	typealias NotaryFactorSource = Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource
	/// When the wallet notarized transactions it should be able to do that without the input from the user (except auth with Biometrics...)
	/// thus we use the "OnDeviceFactorSource" which is the `Curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource`
	/// as factor source for notary private key.
	var notaryFactorSource: NotaryFactorSource {
		curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first
	}
}

// MARK: - NoNonHardwareHierarchicalDeterministicFactorSourceFound
public struct NoNonHardwareHierarchicalDeterministicFactorSourceFound: Swift.Error {}

public extension FactorSources {
	func anyNonHardwareHierarchicalDeterministicFactorSource() throws -> any FactorSourceNonHardwareHierarchicalDeterministicProtocol {
		guard let source = anyFactorSources.compactMap({ $0 as? (any FactorSourceNonHardwareHierarchicalDeterministicProtocol) }).first else {
			throw NoNonHardwareHierarchicalDeterministicFactorSourceFound()
		}
		return source
	}

	var anyFactorSources: [any FactorSourceProtocol] {
		curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.rawValue.elements.map { $0 } +
			secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.elements.map { $0 }
	}

	var factorSources: [FactorSource] {
		curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.rawValue.elements.map { $0.wrapAsFactorSource() } +
			secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.elements.map { $0.wrapAsFactorSource() }
	}

	func find(reference: FactorSourceReference) -> (any FactorSourceProtocol)? {
		anyFactorSources.first(where: { $0.reference == reference })
	}
}

public extension FactorSources {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources": curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.rawValue.elements,
				"secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources": secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources.elements,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		"curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources": \(curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources),
		"secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources": \(secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources),
		"""
	}
}
