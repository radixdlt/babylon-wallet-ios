import Foundation

public extension Home.AccountDetails {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case aggregatedValue(Home.AggregatedValue.Action)
	}
}

public extension Home.AccountDetails.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

public extension Home.AccountDetails.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountDetails
		case displayAccountPreferences
		case copyAddress
		case displayTransfer
	}
}

public extension Home.AccountDetails.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountDetails
		case displayAccountPreferences
		case copyAddress(String)
		case displayTransfer
	}
}
