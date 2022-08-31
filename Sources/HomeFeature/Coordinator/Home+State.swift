import Foundation
import Wallet

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	typealias AggregatedValueSubState = (isCurrencyAmountVisible: Bool, aggregatedValue: AggregatedValue.State)
//	typealias AccountDetailsSubState = (isCurrencyAmountVisible: Bool, accountDetails: AccountDetails.State?)
//	typealias AccountListSubState = (isCurrencyAmountVisible: Bool, accountList: AccountList.State)
	//    typealias AccountRowSubState = (isCurrencyAmountVisible: Bool, accountRow: AccountRow.State)

	// MARK: State
	struct State: Equatable {
		public var wallet: Wallet
		public var accountDetails: Home.AccountDetails.State?
		public var accountList: Home.AccountList.State
		public var accountPreferences: Home.AccountPreferences.State?
		public var aggregatedValue: Home.AggregatedValue.State
		public var createAccount: Home.CreateAccount.State?
		public var header: Home.Header.State
		public var visitHub: Home.VisitHub.State
		public var transfer: Home.Transfer.State?

		public var aggregatedValueSubState: AggregatedValueSubState {
			get {
				(wallet.profile.isCurrencyAmountVisible, aggregatedValue)
			}
			set {
				wallet.profile.isCurrencyAmountVisible = newValue.isCurrencyAmountVisible
				aggregatedValue = newValue.aggregatedValue
			}
		}

		/*
		 public var accountDetailsSubState: AccountDetailsSubState {
		 	get {
		 		(wallet.profile.isCurrencyAmountVisible, accountDetails)
		 	} set {
		 		wallet.profile.isCurrencyAmountVisible = newValue.isCurrencyAmountVisible
		 		accountDetails = newValue.accountDetails
		 	}
		 }
		 */

		/*
		 /        */

		/*
		 public var accountRowSubState: AccountRowSubState {
		     get {
		         (wallet.profile.isCurrencyAmountVisible, accountRow)
		     }
		     set {
		         wallet.profile.isCurrencyAmountVisible = newValue.isCurrencyAmountVisible
		         accountRow = newValue.accountRow
		     }
		 }
		 */

		public init(
			wallet: Wallet,
			accountDetails: Home.AccountDetails.State? = nil,
			accountList _: Home.AccountList.State = .init(accounts: []),
			accountPreferences: Home.AccountPreferences.State? = nil,
			aggregatedValue: Home.AggregatedValue.State = .init(),
			createAccount: Home.CreateAccount.State? = nil,
			header: Home.Header.State = .init(),
			visitHub: Home.VisitHub.State = .init(),
			transfer: Home.Transfer.State? = nil
		) {
			self.wallet = wallet
			self.accountDetails = accountDetails
			accountList = .init(accounts: wallet.profile.accounts)
			self.accountPreferences = accountPreferences
			self.aggregatedValue = aggregatedValue
			self.createAccount = createAccount
			self.header = header
			self.visitHub = visitHub
			self.transfer = transfer
		}
	}
}

#if DEBUG
public extension Home.State {
	static let placeholder = Home.State(
		wallet: .placeholder,
		aggregatedValue: .placeholder,
		header: .init(hasNotification: false),
		visitHub: .init()
	)
}
#endif
