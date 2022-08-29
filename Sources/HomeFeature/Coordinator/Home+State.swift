import CreateAccount
import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var accountDetails: Home.AccountDetails.State?
		public var accountList: Home.AccountList.State
		public var accountPreferences: Home.AccountPreferences.State?
		public var aggregatedValue: Home.AggregatedValue.State
		public var createAccount: CreateAccount.State?
		public var header: Home.Header.State
		public var visitHub: Home.VisitHub.State
		public var transfer: Home.Transfer.State?

		public init(
			account: Home.AccountDetails.State? = nil,
			accountList: Home.AccountList.State = .init(),
			accountPreferences: Home.AccountPreferences.State? = nil,
			aggregatedValue: Home.AggregatedValue.State = .init(),
			createAccount: CreateAccount.State? = nil,
			header: Home.Header.State = .init(),
			visitHub: Home.VisitHub.State = .init(),
			transfer _: Home.Transfer.State? = nil
		) {
			accountDetails = account
			self.accountList = accountList
			self.accountPreferences = accountPreferences
			self.aggregatedValue = aggregatedValue
			self.createAccount = createAccount
			self.header = header
			self.visitHub = visitHub
		}
	}
}

#if DEBUG
public extension Home.State {
	static let placeholder = Home.State(
		accountList: .init(accounts: .placeholder),
		aggregatedValue: .placeholder,
		header: .init(hasNotification: false),
		visitHub: .init()
	)
}
#endif
