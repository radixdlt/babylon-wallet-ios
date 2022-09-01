import Foundation
import Profile
import Wallet

public extension Home.AccountList {
	// MARK: Environment
	struct Environment {
		public let valueFetcher: ValueFetcher

		public init(
			valueFetcher: ValueFetcher = ValueFetcher()
		) {
			self.valueFetcher = valueFetcher
		}
	}
}

// MARK: - ValueFetcher
public struct ValueFetcher {
	public init() {}
	func fetchValuesForAccount(addresses _: [Profile.Account.Address]) {}
}
