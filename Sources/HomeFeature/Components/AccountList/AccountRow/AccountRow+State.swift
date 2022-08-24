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
		public let currency: FiatCurrency
		public let name: String?
		public let tokens: [Token]

		public init(
			address: String,
			aggregatedValue: Float?,
			currency: FiatCurrency,
			name: String?,
			tokens: [Token]
		) {
			self.address = address
			self.aggregatedValue = aggregatedValue
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
	init(profileAccount: Profile.Account) {
		self.init(
			address: profileAccount.address,
			aggregatedValue: profileAccount.aggregatedValue,
			currency: .usd, // FIXME: propagate value from profileAccount
			name: profileAccount.name,
			tokens: []
		)
	}
}

#if DEBUG
public extension Home.AccountRow.State {
	static let placeholder: Self = .init(
		profileAccount: .init(address: "rdr12hj3cqqG89ijHsjA3cq2qgtxg4sahjU78s",
		                      aggregatedValue: 1_000_000,
		                      currency: FiatCurrency.usd.rawValue, // FIXME: use correct type for fiat currency, not String
		                      name: "My account")
	)

	static let radnomTokenPlaceholder: Self = .init(
		address: "rdr12hj3cqqG89ijHsjA3cq2qgtxg4sahjU78s",
		aggregatedValue: 1_000_000,
		currency: FiatCurrency.usd,
		name: "My account",
		tokens: TokenRandomizer.generateRandomTokens()
	)
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
