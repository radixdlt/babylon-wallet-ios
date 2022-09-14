import AccountWorthFetcher
import Common
import Foundation
import Profile

// MARK: - AccountRow
/// Namespace for AccountRowFeature
public extension Home {
	enum AccountRow {}
}

public extension Home.AccountRow {
	// MARK: State
	struct State: Equatable {
		public let account: Profile.Account
		public let name: String
		public let address: Profile.Account.Address
		public var aggregatedValue: Float?
		public var tokenContainers: [TokenWorthContainer]

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			account: Profile.Account,
			name: String,
			address: String,
			aggregatedValue: Float?,
			tokenContainers: [TokenWorthContainer],
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
			self.account = account
			self.name = name
			self.address = address
			self.aggregatedValue = aggregatedValue
			self.tokenContainers = tokenContainers
			self.currency = currency
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
		}
	}
}

// MARK: - Convenience
public extension Home.AccountRow.State {
	init(account: Profile.Account) {
		self.init(
			account: account,
			name: account.name,
			address: account.address,
			aggregatedValue: nil,
			tokenContainers: [],
			currency: .usd,
			isCurrencyAmountVisible: false
		)
	}
}

// MARK: - Home.AccountRow.State + Identifiable
extension Home.AccountRow.State: Identifiable {
	public typealias ID = Profile.Account.Address

	public var id: Profile.Account.Address {
		address
	}
}

#if DEBUG
public extension Home.AccountRow.State {
	static let placeholder: Self = .init(
		account: .init(address: .random,
		               name: "My account")
	)

	/*
	 static let radnomTokenPlaceholder: Self = .init(
	 	address: .random,
	 	aggregatedValue: 1_000_000,
	 	isValueVisible: false,
	 	currency: FiatCurrency.usd,
	 	name: "My account",
	 	tokens: TokenRandomizer.generateRandomTokens()
	 )
	 */
}
#endif

/*
 // FIXME: fiatTotalValueString
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
 */
