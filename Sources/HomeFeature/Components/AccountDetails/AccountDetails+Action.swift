import Foundation
import Profile

public extension Home.AccountDetails {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case aggregatedValue(Home.AggregatedValue.Action)
		case assetList(Home.AssetList.Action)
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
		case refresh
	}
}

public extension Home.AccountDetails.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountDetails
		case displayAccountPreferences
		case copyAddress(Profile.Account.Address)
		case displayTransfer
		case refresh(Profile.Account.Address)
	}
}
