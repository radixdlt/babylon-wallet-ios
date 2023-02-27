import FeaturePrelude

// MARK: - AssetTransfer.Action
extension AssetTransfer {
	// MARK: Action
	public enum Action: Sendable, Equatable {
		case child(ChildAction)
		public static func view(_ action: ViewAction) -> Self { .internal(.view(action)) }
		case `internal`(InternalAction)
		case delegate(DelegateAction)
	}
}

// MARK: - AssetTransfer.Action.ChildAction
extension AssetTransfer.Action {
	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<AssetTransfer.Destinations.Action>)
	}
}

// MARK: - AssetTransfer.Action.ViewAction
extension AssetTransfer.Action {
	public enum ViewAction: Sendable, Equatable {
		case appeared
		case amountTextFieldChanged(String)
		case toAddressTextFieldChanged(String)
		case nextButtonTapped(amount: Decimal_, toAddress: AccountAddress)
	}
}

// MARK: - AssetTransfer.Action.InternalAction
extension AssetTransfer.Action {
	public enum InternalAction: Sendable, Equatable {
		case view(ViewAction)
		case system(SystemAction)
	}
}

// MARK: - AssetTransfer.Action.InternalAction.SystemAction
extension AssetTransfer.Action.InternalAction {
	public enum SystemAction: Sendable, Equatable {}
}

// MARK: - AssetTransfer.Action.DelegateAction
extension AssetTransfer.Action {
	public enum DelegateAction: Sendable, Equatable {}
}
