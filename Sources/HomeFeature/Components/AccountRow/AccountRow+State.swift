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
		public let name: String
		public let address: String
		public var aggregatedValue: Float?
		public var tokenContainers: [TokenWorthContainer]

		// MARK: - AppSettings properties
		public var currency: FiatCurrency
		public var isCurrencyAmountVisible: Bool

		public init(
			name: String,
			address: String,
			aggregatedValue: Float?,
			tokenContainers: [TokenWorthContainer],
			currency: FiatCurrency,
			isCurrencyAmountVisible: Bool
		) {
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

// MARK: - Computed Properties
public extension Home.AccountRow.State {
	var sectionedTokenContainers: [[TokenWorthContainer]] {
		var xrdContainer: TokenWorthContainer?
		var noValueTokens = [TokenWorthContainer]()
		var tokensWithValues = [TokenWorthContainer]()

		tokenContainers.forEach {
			if $0.token.code == .xrd {
				xrdContainer = $0
			} else if $0.token.value == nil {
				noValueTokens.append($0)
			} else {
				tokensWithValues.append($0)
			}
		}

		tokensWithValues.sort { $0.token.value! > $1.token.value! }
		noValueTokens.sort { $0.token.code.value < $1.token.code.value }

		var result = [[TokenWorthContainer]]()

		if let xrdContainer = xrdContainer {
			result.append([xrdContainer])
		}

		let otherAssets: [TokenWorthContainer] = tokensWithValues + noValueTokens
		result.append(otherAssets)

		return result
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
