import Prelude

/// YES! DappDefinitionAddress **is** an AccountAddress! NOT to be confused with the
/// address the an component on Ledger, the `DappAddress`.
public typealias DappDefinitionAddress = AccountAddress

// MARK: - AccountAddress
/// The address to an `Account` on the Radix network.
public struct AccountAddress:
	AddressProtocol,
	AddressKindProtocol,
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	CustomDumpStringConvertible
{
	public let address: String
	public init(address: String) throws {
		guard address.starts(with: "account_") else {
			throw NotAnAccountAddress()
		}
		self.address = address
	}
}

// MARK: - NotAnAccountAddress
struct NotAnAccountAddress: Swift.Error {}

extension AccountAddress {
	public static let kind: AddressKind = .account
}

extension AccountAddress {
	public var customDumpDescription: String {
		"AccountAddress(\(address))"
	}
}

extension AccountAddress {
	/// Wraps this specific type of address to the shared
	/// nominal type `Address` (enum)
	public func wrapAsAddress() -> Address {
		.account(self)
	}

	/// Tries to unwraps the nominal type `Address` (enum)
	/// into this specific type.
	public static func unwrap(address: Address) -> Self? {
		switch address {
		case let .account(address): return address
		default: return nil
		}
	}
}
