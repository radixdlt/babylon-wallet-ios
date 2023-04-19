import Cryptography
import Prelude

// MARK: - EntityKind
/// A kind of entity, e.g. the kind `account` or the kind `identity` (used by Persona), used in derivation path scheme.
public enum EntityKind:
	HD.Path.Component.Child.Value,
	SLIP10DerivationPathComponent,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	/// An account entity type
	case account = 525

	/// Used by Persona
	case identity = 618

	public var entityType: any EntityProtocol.Type {
		switch self {
		case .account: return Profile.Network.Account.self
		case .identity: return Profile.Network.Persona.self
		}
	}
}

extension EntityKind {
	public var description: String {
		switch self {
		case .account: return "account"
		case .identity: return "identity"
		}
	}
}
