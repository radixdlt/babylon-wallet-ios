import Prelude

// MARK: - Address
/// Shared nominal type for all addresses.
/// An address to some data on Radix Ledger, address to e.g. `Account`, `Identity`, `Resource` or Dapp.
public enum Address:
	AddressProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	/// AccountAddress
	case account(AccountAddress)

	case identity(IdentityAddress)
}

extension Address {
	public var address: String {
		switch self {
		case let .account(address): return address.address
		case let .identity(address): return address.address
		}
	}

	public var description: String { address }
}

extension Address {
	public var customDumpDescription: String {
		switch self {
		case .account: return "AccountAddress(\(address))"
		case .identity: return "IdentityAddress(\(address))"
		}
	}
}
