import Foundation

public extension Home {
	enum AccountList {}
}

// MARK: - Account
public extension Home.AccountList {
	struct Account: Equatable {
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
public extension Home.AccountList.Account {
	static let placeholder: Self = .checking

	static let checking: Self = .init(
		address: UUID().uuidString,
		name: "Checking",
		tokens: []
	)

	static let savings: Self = .init(
		address: UUID().uuidString,
		name: "Savings",
		tokens: []
	)

	static let shared: Self = .init(
		address: UUID().uuidString,
		name: "Shared",
		tokens: []
	)
}
#endif
