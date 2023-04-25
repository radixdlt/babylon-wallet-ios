import Prelude

// MARK: - LegacyOlympiaAccountAddress
public struct LegacyOlympiaAccountAddress: Sendable, Hashable, CustomDebugStringConvertible {
	/// Bech32, NOT Bech32m, encoded Olympia address
	public let address: NonEmptyString
	public init(address: NonEmptyString) {
		self.address = address
	}
}

extension LegacyOlympiaAccountAddress {
	public var debugDescription: String {
		address.rawValue
	}
}
