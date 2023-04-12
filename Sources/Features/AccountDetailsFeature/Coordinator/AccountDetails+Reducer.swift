import AccountListFeature
import AccountPreferencesFeature
import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature
import AccountPortfoliosClient
import SharedModels

public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let accountState: AccountList.Row.State
                var account: Profile.Network.Account {
                        accountState.account
                }
		public var assets: AssetsView.State

		@PresentationState
		public var destination: Destinations.State?

		public init(for accountState: AccountList.Row.State) {
			self.accountState = accountState
                        self.assets = AssetsView.State(fungibleTokenList: .init(sections: []), nonFungibleTokenList: .init(rows: []))
		}
	}

	public enum ViewAction: Sendable, Equatable {
                case task
		case appeared
		case backButtonTapped
		case preferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
		case pullToRefreshStarted
	}

	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case displayTransfer
		case refresh(AccountAddress)
	}

        public enum InternalAction: Sendable, Equatable {
                case portfolioUpdated(AccountPortfolio)
        }

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case preferences(AccountPreferences.State)
			case transfer(AssetTransfer.State)
		}

		public enum Action: Sendable, Equatable {
			case preferences(AccountPreferences.Action)
			case transfer(AssetTransfer.Action)
		}

		public var body: some ReducerProtocol<State, Action> {
			Scope(state: /State.preferences, action: /Action.preferences) {
				AccountPreferences()
			}
			Scope(state: /State.transfer, action: /Action.transfer) {
				AssetTransfer()
			}
		}
	}

	@Dependency(\.pasteboardClient) var pasteboardClient
        @Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.assets, action: /Action.child .. ChildAction.assets) {
			AssetsView()
		}

		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
                case .task:
                        return .run { [address = state.account.address] send in
                                for try await portfolio in await accountPortfoliosClient.portfolioForAccount(address) {
                                        guard !Task.isCancelled else {
                                                return
                                        }
                                        await send(.internal(.portfolioUpdated(portfolio)))
                                }
                        }
		case .appeared:
                        return .run { [address = state.account.address] _ in
                                try await accountPortfoliosClient.fetchAccountPortfolio(address)
                        }
		case .backButtonTapped:
			return .send(.delegate(.dismiss))
		case .preferencesButtonTapped:
                        state.destination = .preferences(.init(address: state.accountState.account.address))
			return .none
		case .copyAddressButtonTapped:
			return .fireAndForget { [state] in
                                pasteboardClient.copyString(state.accountState.account.address.address)
			}
		case .pullToRefreshStarted:
                        return .send(.delegate(.refresh(state.accountState.account.address)))
		case .transferButtonTapped:
			// FIXME: fix post betanet v2
//			state.destination = .transfer(AssetTransfer.State(from: state.account))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .destination(.presented(.preferences(.delegate(.dismiss)))):
			state.destination = nil
			return .none
                case .assets(.child(.fungibleTokenList(.delegate(.loadMoreTokens)))):
                        return .none
		default:
			return .none
		}
	}

        public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
                switch internalAction {
                case let .portfolioUpdated(portfolio):
                        let xrd = portfolio.fungibleResources.loaded.first!
                        let nonXrd = Array(portfolio.fungibleResources.loaded.suffix(from: 1))
                        state.assets = .init(fungibleTokenList: .init(xrdToken: xrd, nonXrdTokens: nonXrd), nonFungibleTokenList: .init(rows: []))
                        return .none
                }

        }
}
