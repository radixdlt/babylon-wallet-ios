import Prelude

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
	/// Address to an `Account`
	case account

	/// Address to an `Identity` (used by `Persona`s)
	case identity
}
