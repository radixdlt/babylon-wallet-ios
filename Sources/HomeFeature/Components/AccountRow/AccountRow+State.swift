import Foundation
import Profile

// MARK: - AccountRow
/// Namespace for AccountRowFeature
public extension Home {
	enum AccountRow {}
}

public extension Home.AccountRow {
	// MARK: State
	struct State: Equatable, Identifiable {
		public let address: String
		public let aggregatedValue: Float?
		public let isValueVisible: Bool
		public let currency: FiatCurrency
		public let name: String
		public let tokens: [Token]

		public init(
			address: String,
			aggregatedValue: Float?,
			isValueVisible: Bool,
			currency: FiatCurrency,
			name: String,
			tokens: [Token]
		) {
			self.address = address
			self.aggregatedValue = aggregatedValue
			self.isValueVisible = isValueVisible
			self.currency = currency
			self.name = name
			self.tokens = tokens
		}
	}
}

public extension Home.AccountRow.State {
	typealias ID = Profile.Account.Address

	var id: Profile.Account.Address {
		address
	}
}

public extension Home.AccountRow.State {
	init(profileAccount: Profile.Account, isCurrencyAmountVisible: Bool) {
		self.init(
			address: profileAccount.address,
			aggregatedValue: profileAccount.aggregatedValue,
			isValueVisible: isCurrencyAmountVisible,
			currency: .usd, // FIXME: propagate value from profileAccount
			name: profileAccount.name,
			tokens: []
		)
	}
}

#if DEBUG
public extension Home.AccountRow.State {
	static let placeholder: Self = .init(
		profileAccount: .init(address: .random,
		                      aggregatedValue: 1_000_000,
		                      name: "My account"),
		isCurrencyAmountVisible: false
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
