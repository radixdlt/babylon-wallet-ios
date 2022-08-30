import Foundation
import Wallet

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
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

		public init(
			wallet: Wallet,
			accountDetails: Home.AccountDetails.State? = nil,
			accountPreferences: Home.AccountPreferences.State? = nil,
			aggregatedValue _: Home.AggregatedValue.State = .init(),
			createAccount: Home.CreateAccount.State? = nil,
			header: Home.Header.State = .init(),
			visitHub: Home.VisitHub.State = .init(),
			transfer: Home.Transfer.State? = nil
		) {
			self.wallet = wallet
			self.accountDetails = accountDetails
			accountList = .init(profileAccounts: wallet.profile.accounts,
			                    isCurrencyAmountVisible: wallet.profile.isCurrencyAmountVisible)
			self.accountPreferences = accountPreferences
			aggregatedValue = .init(value: 1234,
			                        currency: .usd,
			                        isVisible: wallet.profile.isCurrencyAmountVisible)
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
