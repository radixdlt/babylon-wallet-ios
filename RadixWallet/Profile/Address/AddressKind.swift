

/// A kind of address, e.g. the kind `account` or the kind `identity` or `component` used
/// by `Dapp`.
public enum AddressKind:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	/// RETAddress to an `Account`
	case account

	/// RETAddress to an `Identity` (used by `Persona`s)
	case identity
}
