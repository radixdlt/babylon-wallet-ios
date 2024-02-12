// MARK: - AddressProtocol
/// A type which represents some kind of addressed component on the Radix ledger, e.g.
/// the address for an `Account`, `Identity` or  other `Component` e.g. a `Dapp`,
/// or possibly also a `Resource`.
public protocol AddressProtocol {
	var address: String { get }
}

extension AddressProtocol {
	public func networkId() -> NetworkID {
		panic()
	}
}

extension AddressProtocol where Self: Identifiable, ID == String {
	public var id: String { address }
}

extension CustomStringConvertible where Self: AddressProtocol {
	public var description: String {
		address
	}
}

// MARK: - SpecificAddress + AddressProtocol
extension SpecificAddress: AddressProtocol {}
