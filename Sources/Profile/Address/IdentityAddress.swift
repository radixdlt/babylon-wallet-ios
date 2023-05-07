import Prelude

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
		guard address.starts(with: "identity_") else {
			throw NotAnIdentityAddress()
		}
		self.address = address
	}
}

// MARK: - NotAnIdentityAddress
struct NotAnIdentityAddress: Swift.Error {}

extension IdentityAddress {
	public static let kind: AddressKind = .identity
}

extension IdentityAddress {
	public var customDumpDescription: String {
		"IdentityAddress(\(address))"
	}
}

extension IdentityAddress {
	/// Wraps this specific type of address to the shared
	/// nominal type `Address` (enum)
	public func wrapAsAddress() -> Address {
		.identity(self)
	}

	/// Tries to unwraps the nominal type `Address` (enum)
	/// into this specific type.
	public static func unwrap(address: Address) -> Self? {
		switch address {
		case let .identity(address): return address
		default: return nil
		}
	}
}

extension IdentityAddress {
	public var description: String {
		customDumpDescription
	}
}

extension AccountAddress {
	public var description: String {
		customDumpDescription
	}
}
