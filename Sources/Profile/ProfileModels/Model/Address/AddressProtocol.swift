import Foundation

// MARK: - AddressProtocol
/// A type which represents some kind of addressed component on the Radix ledger, e.g.
/// the address for an `Account`, `Identity` or  other `Component` e.g. a `Dapp`,
/// or possibly also a `Resource`.
public protocol AddressProtocol {
	var address: String { get }
}

public extension AddressProtocol where Self: Identifiable, ID == String {
	var id: String { address }
}

public extension CustomStringConvertible where Self: AddressProtocol {
	var description: String {
		address
	}
}

// MARK: - AddressKindProtocol
/// A type which has an address kind.
public protocol AddressKindProtocol: AddressProtocol, Codable {
	init(address: String) throws

	/// The kind of address
	static var kind: AddressKind { get }

	/// Wraps this specific type of address to the shared
	/// nominal type `Address` (enum)
	func wrapAsAddress() -> Address

	/// Tries to unwraps the nominal type `Address` (enum)
	/// into this specific type.
	static func unwrap(address: Address) -> Self?
}

public extension AddressKindProtocol {
	init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		try self.init(address: singleValueContainer.decode(String.self))
	}

	func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(self.address)
	}
}
