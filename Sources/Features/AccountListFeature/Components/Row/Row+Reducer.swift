import FeaturePrelude

// MARK: - AccountList.Row
extension AccountList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: AccountAddress { account.address }

			public let account: Profile.Network.Account

			public init(
				account: Profile.Network.Account
			) {
				self.account = account
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case copyAddressButtonTapped
			case tapped
		}

		public init() {}
	}
}
