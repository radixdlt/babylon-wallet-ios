import Address
import AggregatedValueFeature
import AssetListFeature

// MARK: - AccountDetails.Action
public extension AccountDetails {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
		case aggregatedValue(AggregatedValue.Action)
		case assetList(AssetList.Action)
	}
}

// MARK: - AccountDetails.Action.InternalAction
public extension AccountDetails.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
	}
}

// MARK: - AccountDetails.Action.InternalAction.UserAction
public extension AccountDetails.Action.InternalAction {
	enum UserAction: Equatable {
		case dismissAccountDetails
		case displayAccountPreferences
		case copyAddress
		case displayTransfer
		case refresh
	}
}

// MARK: - AccountDetails.Action.CoordinatingAction
public extension AccountDetails.Action {
	enum CoordinatingAction: Equatable {
		case dismissAccountDetails
		case displayAccountPreferences
		case copyAddress(Address)
		case displayTransfer
		case refresh(Address)
	}
}
