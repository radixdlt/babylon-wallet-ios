import Foundation

// MARK: - Profile
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

#if DEBUG
public extension Profile {
	static let placeholder: Profile = .init(name: "Placeholder account", accounts: [
		.init(address: .random,
		      aggregatedValue: Float.random(in: 100 ... 1_000_000),
		      name: "Checking"),
		.init(address: .random,
		      aggregatedValue: Float.random(in: 100 ... 1_000_000),
		      name: "Savings"),
	], isCurrencyAmountVisible: false)
}
#endif
