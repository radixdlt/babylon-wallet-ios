import EngineToolkit
import Prelude

/// YES! DappDefinitionAddress **is** an AccountAddress! NOT to be confused with the
/// address the an component on Ledger, the `DappAddress`.
public typealias DappDefinitionAddress = AccountAddress

extension DappDefinitionAddress {
	/// This address is just a placeholder for now to be compatible with DappInteractor flow
	public static let wallet: Self = try! .init(address: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p")
}

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
		let decoded = try RadixEngine.instance.decodeAddressRequest(request: .init(address: address)).get()
		guard decoded.isAccountAddress else {
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

extension DecodeAddressResponse {
	var isAccountAddress: Bool {
		switch entityType {
		case .accountComponent, .ed25519VirtualAccountComponent, .secp256k1VirtualAccountComponent:
			return true
		default:
			return false
		}
	}
}
