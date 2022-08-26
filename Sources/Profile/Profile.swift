import Foundation

public struct Profile: Equatable {
	public let accounts: [Account]
	public let name: String
	public var isCurrencyAmountVisible: Bool

	public init(
		name: String = "Unnamed",
		accounts: [Account] = [],
		isCurrencyAmountVisible: Bool = false
	) {
		self.name = name
		self.accounts = accounts
		self.isCurrencyAmountVisible = isCurrencyAmountVisible
	}
}
