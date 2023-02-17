import Prelude

// MARK: - CustomHierarchicalDeterministicDerivationPath
/// A **custom** derivation path used to derive keys for whatever purpose. [CAP-26][cap26] states
/// that custom derivation paths must be supported.
///
/// The format is:
///
///     `m/44'/1022'`
///
/// Where `'` denotes hardened path, which is **required** as per [SLIP-10][slip10].
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
/// [slip10]: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
///
public struct CustomHierarchicalDeterministicDerivationPath:
	DerivationPathProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public let derivationPath: String
	public init(derivationPath: String) throws {
		self.derivationPath = derivationPath
	}
}

extension CustomHierarchicalDeterministicDerivationPath {
	public var customDumpDescription: String {
		_description
	}

	public var description: String {
		_description
	}

	public var _description: String {
		"CustomHierarchicalDeterministicDerivationPath(\(derivationPath))"
	}
}

extension CustomHierarchicalDeterministicDerivationPath {
	public func wrapAsDerivationPath() -> DerivationPath {
		.customPath(self)
	}

	/// Tries to unwraps the nominal type `DerivationPath` (enum)
	/// into this specific type.
	public static func unwrap(derivationPath: DerivationPath) -> Self? {
		try? derivationPath.asCustomPath()
	}
}
