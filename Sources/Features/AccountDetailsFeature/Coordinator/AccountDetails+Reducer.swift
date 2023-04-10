import AccountListFeature
import AccountPreferencesFeature
import AssetsViewFeature
import AssetTransferFeature
import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature
import AccountPortfolioFetcherClient

public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let accountState: AccountList.Row.State
		public var assets: AssetsView.State
                //public var portfolio: AccountPortofolo

		@PresentationState
		public var destination: Destinations.State?

		public init(for accountState: AccountList.Row.State) {
			self.accountState = accountState

                        let fungibleTokenCategories = accountState.portfolio.fungibleTokenContainers.sortedIntoCategories()

			assets = .init(
				fungibleTokenList: .init(
					sections: .init(uniqueElements: fungibleTokenCategories.map { category in
						let rows = category.containers.map { container in
							FungibleTokenList.Row.State(
								container: container,
								currency: accountState.currency,
								isCurrencyAmountVisible: accountState.isCurrencyAmountVisible
							)
						}
						return FungibleTokenList.Section.State(
                                                        id: category.id,
                                                        assets: .init(uniqueElements: rows)
						)
					})
				),

				nonFungibleTokenList: .init(
					rows: .init(uniqueElements: accountState.portfolio.nonFungibleTokenContainers.map {
						.init(container: $0)
					})
				)
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
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

        public enum InternAction: Sendable, Equatable {
                case loadMoreFungibleTokensResult(TaskResult<FungibleTokensPageResponse>)
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
        @Dependency(\.accountPortfolioFetcherClient) var accountPortfolioFetcherClient

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
		case .appeared:
                        return .send(.delegate(.refresh(state.accountState.account.address)))
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
                        guard let nextPageCursor = state.accountState.portfolio.fungibleTokenContainers.nextPageCursor else {
                                return .none
                        }

                        accountPortfolioFetcherClient.fetchFungibleTokens(nextPageCursor)
                        return .none
		default:
			return .none
		}
	}
}
