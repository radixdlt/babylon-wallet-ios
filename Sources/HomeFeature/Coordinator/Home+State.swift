import Foundation
import Profile
import Wallet

// MARK: - AccountWorth
public struct AccountWorth: Equatable {
	public let address: Profile.Account.Address
	public let worth: Float
}

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	typealias AccountsWorthDictionary = [Profile.Account.Address: AccountWorth]

	// MARK: State
	struct State: Equatable {
		public var wallet: Wallet
		public var accountsWorthDictionary: [Profile.Account.Address: AccountWorth] {
			didSet {
				// TODO: this or update the state of all the subcomponents in reducer
				aggregatedValue.value = accountsWorthDictionary.map(\.value.worth).reduce(0, +)
			}
		}

		// MARK: - Components
		public var header: Home.Header.State
		public var aggregatedValue: Home.AggregatedValue.State
		public var accountList: Home.AccountList.State
		public var visitHub: Home.VisitHub.State

		// MARK: - Children
		public var accountDetails: Home.AccountDetails.State?
		public var accountPreferences: Home.AccountPreferences.State?
		public var createAccount: Home.CreateAccount.State?
		public var transfer: Home.Transfer.State?

		public init(
			wallet: Wallet,
			accountsWorthDictionary: AccountsWorthDictionary = [:],
			header: Home.Header.State = .init(),
			aggregatedValue: Home.AggregatedValue.State = .init(),
			accountList: Home.AccountList.State = .init(accounts: []),
			visitHub: Home.VisitHub.State = .init(),
			accountDetails: Home.AccountDetails.State? = nil,
			accountPreferences: Home.AccountPreferences.State? = nil,
			createAccount: Home.CreateAccount.State? = nil,
			transfer: Home.Transfer.State? = nil
		) {
			self.wallet = wallet
			self.accountsWorthDictionary = accountsWorthDictionary
			self.header = header
			self.aggregatedValue = aggregatedValue
			self.accountList = accountList
			self.visitHub = visitHub
			self.accountDetails = accountDetails
			self.accountPreferences = accountPreferences
			self.createAccount = createAccount
			self.transfer = transfer
		}
	}
}

// MARK: - Convenience
public extension Home.State {
	init(justA wallet: Wallet) {
		self.init(
			wallet: wallet,
			accountList: .init(just: wallet.profile.accounts)
		)
	}
}

#if DEBUG
public extension Home.State {
	static let placeholder = Home.State(
		wallet: .placeholder,
		header: .init(hasNotification: false),
		aggregatedValue: .placeholder,
		visitHub: .init()
	)
}
#endif
