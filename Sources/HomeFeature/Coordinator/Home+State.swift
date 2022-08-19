import Foundation

// MARK: - Home
/// Namespace for HomeFeature
public enum Home {}

public extension Home {
	// MARK: State
	struct State: Equatable {
		public var accountList: Home.AccountList.State
		public var aggregatedValue: Home.AggregatedValue.State
		public var header: Home.Header.State
		public var visitHub: Home.VisitHub.State

		public init(
			accountList: Home.AccountList.State = .init(),
			aggregatedValue: Home.AggregatedValue.State = .init(),
			header: Home.Header.State = .init(),
			visitHub: Home.VisitHub.State = .init()
		) {
			self.accountList = accountList
			self.aggregatedValue = aggregatedValue
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
