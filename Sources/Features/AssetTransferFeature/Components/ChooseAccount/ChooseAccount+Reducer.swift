import FeaturePrelude

public struct ChooseAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum DelegateAction: Equatable, Sendable {
		case addOwnedAccount(Profile.Network.Account)
		case addExternalAccount(AccountAddress)
	}
}
