import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - AccountHierarchicalDeterministicDerivationPath
/// The **default** derivation path used to derive `Account` keys for signing of
/// transactions or for signing authentication, at a certain account index (`ENTITY_INDEX`)
/// and **unique per network** (`NETWORK_ID`) as per [CAP-26][cap26].
///
/// Note that users can chose to use custom derivation path instead of this default
/// one when deriving keys for accounts.
///
/// The format is:
///
///     `m/44'/1022'/<NETWORK_ID>'/525'/<ENTITY_INDEX>'/<KEY_TYPE>'`
///
/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10],
/// where `525` is ASCII sum of `"ACCOUNT"`, i.e. `"ACCOUNT".map{ $0.asciiValue! }.reduce(0, +)`
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
///
public struct AccountHierarchicalDeterministicDerivationPath:
	EntityDerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public typealias Entity = Profile.Network.Account
	public let fullPath: HD.Path.Full

	public init(
		networkID: NetworkID,
		index: Profile.Network.NextDerivationIndices.Index,
		keyKind: KeyKind
	) throws {
		try self.init(fullPath: HD.Path.Full.account(
			networkID: networkID,
			index: index,
			keyKind: keyKind
		))
	}

	public init(fullPath: HD.Path.Full) throws {
		self.fullPath = try Self.validate(hdPath: fullPath)
	}
}

extension AccountHierarchicalDeterministicDerivationPath {
	public var customDumpDescription: String {
		"AccountHierarchicalDeterministicDerivationPath(\(derivationPath))"
	}

	public var description: String {
		"""
		AccountHierarchicalDeterministicDerivationPath: \(derivationPath),
		"""
	}
}

extension AccountHierarchicalDeterministicDerivationPath {
	/// Wraps this specific type of derivation path to the shared
	/// nominal type `DerivationPath` (enum)
	public func wrapAsDerivationPath() -> DerivationPath {
		.accountPath(self)
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		try? derivationPath.asAccountPath()
	}
}
