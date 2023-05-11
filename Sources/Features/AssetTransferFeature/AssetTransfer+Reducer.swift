import FeaturePrelude

public struct AssetTransfer: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let message: String?
		let fromAccount: Profile.Network.Account
		let toAccounts: [Profile.Network.Account]
	}

	public enum ViewAction: Equatable, Sendable {}
}
