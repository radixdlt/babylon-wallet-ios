import FeaturePrelude

// MARK: - AssetsViewMode
public enum AssetsViewMode: Hashable, Sendable {
	public struct SelectedItems: Hashable, Sendable {
		public struct NonFungibleTokensPerResource: Hashable, Sendable, Identifiable {
			public var id: ResourceAddress {
				resourceAddress
			}

			public let resourceAddress: ResourceAddress
			public var tokens: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>

			public init(resourceAddress: ResourceAddress, tokens: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>) {
				self.resourceAddress = resourceAddress
				self.tokens = tokens
			}
		}

		public var fungibleResources: AccountPortfolio.FungibleResources
		public var nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource>

		public var isEmpty: Bool {
			fungibleResources.xrdResource == nil &&
				fungibleResources.nonXrdResources.isEmpty &&
				nonFungibleResources.isEmpty
		}

		public init(
			fungibleResources: AccountPortfolio.FungibleResources = .init(),
			nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource> = []
		) {
			self.fungibleResources = fungibleResources
			self.nonFungibleResources = nonFungibleResources
		}
	}

	case normal
	case selection(SelectedItems)

	public var isSelection: Bool {
		if case .selection = self {
			return true
		}
		return false
	}
}

// MARK: - AssetsView
public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// All of the possible asset list
		public enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
			case tokens
			case nfts

			var displayText: String {
				switch self {
				case .tokens:
					return L10n.Account.tokens
				case .nfts:
					return L10n.Account.nfts
				}
			}
		}

		public var activeAssetKind: AssetKind
		public var assetKinds: NonEmpty<[AssetKind]>
		public var fungibleTokenList: FungibleAssetList.State
		public var nonFungibleTokenList: NonFungibleAssetList.State

		public let account: Profile.Network.Account
		public var isLoadingResources: Bool = false

		public let mode: AssetsViewMode

		public init(account: Profile.Network.Account, mode: AssetsViewMode = .selection(.init())) {
			self.init(
				account: account,
				fungibleTokenList: .init(),
				nonFungibleTokenList: .init(rows: []),
				mode: mode
			)
		}

		init(
			account: Profile.Network.Account,
			assetKinds: NonEmpty<[AssetKind]> = .init([.tokens, .nfts])!,
			fungibleTokenList: FungibleAssetList.State,
			nonFungibleTokenList: NonFungibleAssetList.State,
			mode: AssetsViewMode
		) {
			self.account = account
			self.assetKinds = assetKinds
			self.activeAssetKind = assetKinds.first
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case pullToRefreshStarted
		case didSelectList(State.AssetKind)
		case chooseButtonTapped(AssetsViewMode.SelectedItems)
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleAssetList.Action)
		case nonFungibleTokenList(NonFungibleAssetList.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case portfolioUpdated(AccountPortfolio)
	}

	public enum DelegateAction: Sendable, Equatable {
		case handleSelectedAssets(AssetsViewMode.SelectedItems)
		case dismiss
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
			NonFungibleAssetList()
		}

		Scope(state: \.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
			FungibleAssetList()
		}
		Reduce(self.core)
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
		case let .didSelectList(kind):
			state.activeAssetKind = kind
			return .none
		case .pullToRefreshStarted:
			return .run { [address = state.account.address] _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolio(address, true)
			}
		case let .chooseButtonTapped(items):
			return .send(.delegate(.handleSelectedAssets(items)))
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .portfolioUpdated(portfolio):
			let xrd = portfolio.fungibleResources.xrdResource.map {
				FungibleAssetList.Row.State(xrdToken: $0, isSelected: state.mode.xrdRowSelected)
			}
			let nonXrd = portfolio.fungibleResources.nonXrdResources.map {
				FungibleAssetList.Row.State(nonXRDToken: $0, isSelected: state.mode.nonXrdRowSelected($0.resourceAddress))
			}
			let nfts = portfolio.nonFungibleResources.map {
				NonFungibleAssetList.Row.State(resource: $0, selectedAssets: state.mode.nftRowSelectedAssets($0.resourceAddress))
			}

			state.fungibleTokenList = .init(xrdToken: xrd, nonXrdTokens: .init(uniqueElements: nonXrd))
			state.nonFungibleTokenList = .init(rows: .init(uniqueElements: nfts))
			return .none
		}
	}
}

extension AssetsView.State {
	public var selectedItems: AssetsViewMode.SelectedItems? {
		guard case .selection = mode else { return nil }

		func selectedFungibleResource(_ row: FungibleAssetList.Row.State) -> AccountPortfolio.FungibleResource? {
			if row.isSelected == true {
				return row.token
			}
			return nil
		}

		let fungibleresources = AccountPortfolio.FungibleResources(
			xrdResource: fungibleTokenList.xrdToken.flatMap(selectedFungibleResource),
			nonXrdResources: fungibleTokenList.nonXrdTokens.compactMap(selectedFungibleResource)
		)

		let nonFungibleResources = nonFungibleTokenList.rows.compactMap {
			if let selectedAssets = $0.selectedAssets, !selectedAssets.isEmpty {
				return AssetsViewMode.SelectedItems.NonFungibleTokensPerResource(resourceAddress: $0.resource.resourceAddress, tokens: selectedAssets)
			}
			return nil
		}

		guard fungibleresources.xrdResource != nil || !fungibleresources.nonXrdResources.isEmpty || !nonFungibleResources.isEmpty else {
			return nil
		}

		return .init(
			fungibleResources: fungibleresources,
			nonFungibleResources: IdentifiedArrayOf(uniqueElements: nonFungibleResources)
		)
	}
}

extension AssetsViewMode {
	var xrdRowSelected: Bool? {
		switch self {
		case .normal:
			return nil
		case let .selection(items):
			return items.fungibleResources.xrdResource != nil
		}
	}

	func nonXrdRowSelected(_ resource: ResourceAddress) -> Bool? {
		switch self {
		case .normal:
			return nil
		case let .selection(items):
			return items.fungibleResources.nonXrdResources.contains { $0.resourceAddress == resource }
		}
	}

	func nftRowSelectedAssets(_ resource: ResourceAddress) -> NonFungibleAssetList.Row.State.SelectedAssets? {
		switch self {
		case .normal:
			return nil
		case let .selection(items):
			return items.nonFungibleResources[id: resource]?.tokens ?? []
		}
	}
}
