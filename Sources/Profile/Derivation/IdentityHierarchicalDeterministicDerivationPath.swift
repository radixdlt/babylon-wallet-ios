import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - IdentityHierarchicalDeterministicDerivationPath
/// The **default** derivation path used to derive `Identity` (Persiba) keys
/// for signing authentication, at a certain (Persona) index (`ENTITY_INDEX`)
/// and **unique per network** (`NETWORK_ID`) as per [CAP-26][cap26].
///
/// Note that users can chose to use custom derivation path instead of this default
/// one when deriving keys for identities (personas).
///
/// The format is:
///
///     `m/44'/1022'/<NETWORK_ID>'/618'/<ENTITY_INDEX>'/<KEY_TYPE>'`
///
/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
/// where `618` is ASCII sum of `"IDENTITY"`, i.e. `"IDENTITY".map{ $0.asciiValue! }.reduce(0, +)`
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
///
public struct IdentityHierarchicalDeterministicDerivationPath:
	EntityDerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public typealias Entity = OnNetwork.Persona
	public let fullPath: HD.Path.Full

	public init(
		networkID: NetworkID,
		index: Int,
		keyKind: KeyKind
	) throws {
		try self.init(fullPath: HD.Path.Full.identity(
			networkID: networkID,
			index: index,
			keyKind: keyKind
		))
	}

	public init(fullPath: HD.Path.Full) throws {
		self.fullPath = try Self.validate(hdPath: fullPath)
	}
}

extension IdentityHierarchicalDeterministicDerivationPath {
	public static let purpose: DerivationPurpose = .publicKeyForAddress(kind: .identity)
	public static let derivationScheme: DerivationScheme = .slip10
}

extension IdentityHierarchicalDeterministicDerivationPath {
	public var _description: String {
		"IdentityHierarchicalDeterministicDerivationPath(\(derivationPath))"
	}

	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}
}

extension IdentityHierarchicalDeterministicDerivationPath {
	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	public func wrapAsDerivationPath() -> DerivationPath {
		.identityPath(self)
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		try? derivationPath.asIdentityPath()
	}
}
