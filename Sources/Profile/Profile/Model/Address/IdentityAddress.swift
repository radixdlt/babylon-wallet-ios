import CustomDump
import Foundation

// MARK: - IdentityAddress
/// The address to an `Identity` on the Radix network, used by `Persona`s.
public struct IdentityAddress:
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

public extension IdentityAddress {
	static let kind: AddressKind = .identity
}

public extension IdentityAddress {
	var customDumpDescription: String {
		"IdentityAddress(\(address))"
	}
}

public extension IdentityAddress {
	/// Wraps this specific type of address to the shared
	/// nominal type `Address` (enum)
	func wrapAsAddress() -> Address {
		.identity(self)
	}

	/// Tries to unwraps the nominal type `Address` (enum)
	/// into this specific type.
	static func unwrap(address: Address) -> Self? {
		switch address {
		case let .identity(address): return address
		default: return nil
		}
	}
}

public extension IdentityAddress {
	var description: String {
		customDumpDescription
	}
}

public extension AccountAddress {
	var description: String {
		customDumpDescription
	}
}
