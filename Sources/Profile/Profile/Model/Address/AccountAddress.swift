import CustomDump
import Foundation

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
		self.address = address
	}
}

public extension AccountAddress {
	static let kind: AddressKind = .account
}

public extension AccountAddress {
	var customDumpDescription: String {
		"AccountAddress(\(address))"
	}
}

public extension AccountAddress {
	/// Wraps this specific type of address to the shared
	/// nominal type `Address` (enum)
	func wrapAsAddress() -> Address {
		.account(self)
	}

	/// Tries to unwraps the nominal type `Address` (enum)
	/// into this specific type.
	static func unwrap(address: Address) -> Self? {
		switch address {
		case let .account(address): return address
		default: return nil
		}
	}
}
