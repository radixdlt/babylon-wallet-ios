import ComposableArchitecture
import Foundation
import Profile

// MARK: - AccountList
/// Namespace for AccountListFeature
public extension Home {
	enum AccountList {}
}

public extension Home.AccountList {
	// MARK: State
	struct State: Equatable {
		public var accounts: IdentifiedArrayOf<Home.AccountRow.State>
		public var alert: AlertState<Action>?

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			accounts: IdentifiedArrayOf<Home.AccountRow.State>,
			alert: AlertState<Action>? = nil,
			currency: FiatCurrency = .usd,
			isCurrencyAmountVisible: Bool = false
		) {
			self.accounts = accounts
			self.alert = alert
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Convenience
public extension Home.AccountList.State {
	init(just accounts: [Profile.Account]) {
		self.init(
			accounts: .init(uniqueElements: accounts.map(Home.AccountRow.State.init(account:)))
		)
	}
}

#if DEBUG
public extension Array where Element == Home.AccountRow.State {
//	static let placeholder: Self = [.checking, .savings, .shared, .family, .dummy1, .dummy2, .dummy3]
	static let placeholder: Self = []
}

public extension IdentifiedArray where Element == Home.AccountRow.State, ID == Home.AccountRow.State.ID {
	static let placeholder: Self = .init(uniqueElements: Array<Home.AccountRow.State>.placeholder)
}

public extension Home.AccountRow.State {
	/*
	 static let checking: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Checking",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let savings: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Savings",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let shared: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Shared",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let family: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Family",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let dummy1: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Dummy 1",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let dummy2: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Dummy 2",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )

	 static let dummy3: Self = .init(
	 	address: .random,
	 	aggregatedValue: Float.random(in: 100 ... 1_000_000),
	 	isValueVisible: false,
	 	currency: .usd,
	 	name: "Dummy 3",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )
	 */
}
#endif
