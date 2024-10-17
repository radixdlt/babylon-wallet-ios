import ComposableArchitecture
import SwiftUI

// MARK: - AssetsView
struct AssetsView: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		/// All of the possible asset list
		enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
			case fungible
			case nonFungible
			case stakeUnits
			case poolUnits

			var displayText: String {
				switch self {
				case .fungible:
					L10n.Account.tokens
				case .nonFungible:
					L10n.Account.nfts
				case .stakeUnits:
					L10n.Account.staking
				case .poolUnits:
					L10n.Account.poolUnits
				}
			}
		}

		struct Resources: Hashable, Sendable {
			var fungibleTokenList: FungibleAssetList.State?
			var nonFungibleTokenList: NonFungibleAssetList.State?
			var stakeUnitList: StakeUnitList.State?
			var poolUnitsList: PoolUnitsList.State?
		}

		var activeAssetKind: AssetKind
		var assetKinds: NonEmpty<[AssetKind]>

		var resources: Resources = .init()

		let account: Account
		var accountPortfolio: Loadable<AccountPortfoliosClient.AccountPortfolio> = .idle
		var isLoadingResources: Bool = false
		var isRefreshing: Bool = false
		let mode: Mode
		var totalFiatWorth: Loadable<FiatWorth> = .loading

		init(account: Account, mode: Mode = .normal) {
			self.init(
				account: account,
				resources: .init(),
				mode: mode
			)
		}

		init(
			account: Account,
			assetKinds: NonEmpty<[AssetKind]> = .init(rawValue: AssetKind.allCases)!,
			resources: Resources,
			mode: Mode
		) {
			self.account = account
			self.assetKinds = assetKinds
			self.activeAssetKind = assetKinds.first
			self.resources = resources
			self.mode = mode
		}
	}

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case pullToRefreshStarted
		case didSelectList(State.AssetKind)
		case chooseButtonTapped(State.Mode.SelectedAssets)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleAssetList.Action)
		case nonFungibleTokenList(NonFungibleAssetList.Action)
		case stakeUnitList(StakeUnitList.Action)
		case poolUnitsList(PoolUnitsList.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case portfolioUpdated(AccountPortfoliosClient.AccountPortfolio)
	}

	enum DelegateAction: Sendable, Equatable {
		case handleSelectedAssets(State.Mode.SelectedAssets)
		case selected(Selection)

		enum Selection: Sendable, Equatable {
			case fungible(OnLedgerEntity.OwnedFungibleResource, isXrd: Bool)
			case nonFungible(OnLedgerEntity.OwnedNonFungibleResource, token: OnLedgerEntity.NonFungibleToken)
			case stakeUnit(OnLedgerEntitiesClient.ResourceWithVaultAmount, details: OnLedgerEntitiesClient.OwnedStakeDetails)
			case stakeClaim(OnLedgerEntity.Resource, claim: OnLedgerEntitiesClient.StakeClaim)
			case poolUnit(OnLedgerEntitiesClient.OwnedResourcePoolDetails)
		}
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.resources.fungibleTokenList, action: \.child.fungibleTokenList) {
				FungibleAssetList()
			}
			.ifLet(\.resources.nonFungibleTokenList, action: \.child.nonFungibleTokenList) {
				NonFungibleAssetList()
			}
			.ifLet(\.resources.stakeUnitList, action: \.child.stakeUnitList) {
				StakeUnitList()
			}
			.ifLet(\.resources.poolUnitsList, action: \.child.poolUnitsList) {
				PoolUnitsList()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask:
			state.isLoadingResources = true
			state.accountPortfolio = .loading
			return .run { [state] send in
				for try await portfolio in await accountPortfoliosClient.portfolioForAccount(state.account.address).debounce(for: .seconds(0.1)) {
					guard !Task.isCancelled else { return }
					await send(.internal(.portfolioUpdated(portfolio)))
				}
			} catch: { error, _ in
				loggerGlobal.error("AssetsView portfolioForAccount failed: \(error)")
			}
			.merge(with: fetchAccountPortfolio(state))

		case let .didSelectList(kind):
			state.activeAssetKind = kind
			return .none

		case .pullToRefreshStarted:
			state.isRefreshing = true
			return fetchAccountPortfolio(state)

		case let .chooseButtonTapped(items):
			return .send(.delegate(.handleSelectedAssets(items)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case var .portfolioUpdated(portfolio):
			state.isLoadingResources = false
			state.isRefreshing = false
			portfolio.account = portfolio.account.nonEmptyVaults
			let nftRowsToRefresh = updateFromPortfolio(state: &state, from: portfolio)

			return !nftRowsToRefresh.isEmpty ? .send(.child(.nonFungibleTokenList(.internal(.refreshRows(nftRowsToRefresh))))) : .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .fungibleTokenList(.delegate(.selected(resource, isXrd))):
			.send(.delegate(.selected(.fungible(resource, isXrd: isXrd))))

		case let .nonFungibleTokenList(.delegate(.selected(resource, token))):
			.send(.delegate(.selected(.nonFungible(resource, token: token))))

		case let .stakeUnitList(.delegate(.selected(selection))):
			switch selection {
			case let .unit(resource, details):
				.send(.delegate(.selected(.stakeUnit(resource, details: details))))
			case let .claim(resource, claim):
				.send(.delegate(.selected(.stakeClaim(resource, claim: claim))))
			}

		case let .poolUnitsList(.delegate(.selected(details))):
			.send(.delegate(.selected(.poolUnit(details))))

		default:
			.none
		}
	}

	func fetchAccountPortfolio(_ state: State) -> Effect<Action> {
		.run { [address = state.account.address] _ in
			_ = try await accountPortfoliosClient.fetchAccountPortfolio(address, true)
		} catch: { error, _ in
			loggerGlobal.error("AssetsView fetch failed: \(error)")
			errorQueue.schedule(error)
		}
	}
}
