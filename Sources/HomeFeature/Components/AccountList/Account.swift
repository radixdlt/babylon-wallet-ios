import Foundation

// MARK: - Account
public struct Account: Equatable {
	public let address: String
	public let name: String
	public let tokens: [Token]

	public init(
		address: String,
		name: String,
		tokens: [Token]
	) {
		self.address = address
		self.name = name
		self.tokens = tokens
	}
}

/*
 public extension Account {
 	var fiatTotalValueString: String {
 		fiatTotalValue
 			.formatted(
 				.currency(code: currency.code)
 			)
 	}
 }
 */

#if DEBUG
public extension Account {
	static let placeholder: Account = .checking

	static let checking: Account = .init(
		address: UUID().uuidString,
		name: "Checking",
		tokens: []
	)

	static let savings: Account = .init(
		address: UUID().uuidString,
		name: "Savings",
		tokens: []
	)

	static let shared: Account = .init(
		address: UUID().uuidString,
		name: "Shared",
		tokens: []
	)
}
#endif
