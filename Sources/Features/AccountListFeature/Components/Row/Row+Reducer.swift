import AccountPortfoliosClient
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
			case task
		}

		public init() {}

		// This is showcase of how the portfolio update will be handled in home screen
		// TODO: Wire this fully
		//                @Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
//
		//                public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		//                        switch viewAction {
		//                        case .task:
		//                                let accountAddress = state.account.address
		//                                return .run { send in
		//                                        for try await accountPortfolio in await accountPortfoliosClient.portfolioForAccount(accountAddress) {
		//                                                // handle portfolio update
		//                                        }
		//                                }
		//                        default:
		//                                return .none
		//                        }
		//                }
	}
}
