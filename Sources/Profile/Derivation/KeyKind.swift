import Cryptography
import Prelude

// MARK: - SLIP10DerivationPathComponent
/// A type which is component inside the default SLIP10 deriation path scheme
/// specified in [CAP26][cap26]
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
///
public protocol SLIP10DerivationPathComponent {
	var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { get }
}

extension SLIP10DerivationPathComponent where Self: RawRepresentable, RawValue == HD.Path.Component.Child.Value {
	public var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { rawValue }
}

// MARK: - KeyKind
/// The kind of key being derived, either for signing transactions or for signing authentication
/// This is the last derivation path component of the default derivation path scheme, as per [CAP26][cap26].
///
/// [cap26]: https://radixdlt.atlassian.net/l/cp/UNaBAGUC
public enum KeyKind:
	HD.Path.Component.Child.Value,
	SLIP10DerivationPathComponent,
	CaseIterable,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	/// For a key to be used for signing transactions.
	case transactionSigningKey = 1238

	/// For a key to be used for signing authentication.
	case authenticationSigningKey = 706
}

extension KeyKind {
	// https://rdxworks.slack.com/archives/C031A0V1A1W/p1665751090101519?thread_ts=1665750717.513349&cid=C031A0V1A1W
	public static let virtualEntity = Self.transactionSigningKey
}

extension KeyKind {
	public var description: String {
		switch self {
		case .transactionSigningKey: return "transactionSigningKey"
		case .authenticationSigningKey: return "authenticationSigningKey"
		}
	}
}
