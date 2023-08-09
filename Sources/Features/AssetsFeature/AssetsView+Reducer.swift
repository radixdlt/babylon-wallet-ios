import EngineKit
import FeaturePrelude

// MARK: - AssetsView
public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// All of the possible asset list
		public enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
			case fungible
			case nonFungible
			case poolUnits

			var displayText: String {
				switch self {
				case .fungible:
					return L10n.Account.tokens
				case .nonFungible:
					return L10n.Account.nfts
				case .poolUnits:
					return L10n.Account.poolUnits
				}
			}
		}

		public var activeAssetKind: AssetKind
		public var assetKinds: NonEmpty<[AssetKind]>

		public var fungibleTokenList: FungibleAssetList.State
		public var nonFungibleTokenList: NonFungibleAssetList.State
		public var poolUnitsList: PoolUnitsList.State

		public let account: Profile.Network.Account
		public var isLoadingResources: Bool = false
		public let mode: Mode

		public init(account: Profile.Network.Account, mode: Mode = .normal) {
			self.init(
				account: account,
				fungibleTokenList: .init(),
				nonFungibleTokenList: .init(rows: []),
				poolUnitsList: .init(
					lsuResource: .init(stakes: []),
					poolUnits: [
						.init(id: 0),
						.init(id: 1),
					]
				),
				mode: mode
			)
		}

		init(
			account: Profile.Network.Account,
			assetKinds: NonEmpty<[AssetKind]> = .init(rawValue: AssetKind.allCases)!,
			fungibleTokenList: FungibleAssetList.State,
			nonFungibleTokenList: NonFungibleAssetList.State,
			poolUnitsList: PoolUnitsList.State,
			mode: Mode
		) {
			self.account = account
			self.assetKinds = assetKinds
			self.activeAssetKind = assetKinds.first
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
			self.poolUnitsList = poolUnitsList
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case pullToRefreshStarted
		case didSelectList(State.AssetKind)
		case chooseButtonTapped(State.Mode.SelectedAssets)
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleAssetList.Action)
		case nonFungibleTokenList(NonFungibleAssetList.Action)
		case poolUnitsList(PoolUnitsList.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case portfolioUpdated(AccountPortfolio)
	}

	public enum DelegateAction: Sendable, Equatable {
		case handleSelectedAssets(State.Mode.SelectedAssets)
		case dismiss
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \.fungibleTokenList,
			action: /Action.child .. ChildAction.fungibleTokenList
		) {
			FungibleAssetList()
		}
		Scope(
			state: \.nonFungibleTokenList,
			action: /Action.child .. ChildAction.nonFungibleTokenList
		) {
			NonFungibleAssetList()
		}
		Scope(
			state: \.poolUnitsList,
			action: /Action.child .. ChildAction.poolUnitsList
		) {
			PoolUnitsList()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { [address = state.account.address] send in
				for try await portfolio in await accountPortfoliosClient.portfolioForAccount(address) {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.portfolioUpdated(portfolio.nonEmptyVaults)))
				}
			}
		case let .didSelectList(kind):
			state.activeAssetKind = kind
			return .none
		case .pullToRefreshStarted:
			return .fireAndForget { [address = state.account.address] in
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
			let xrd = portfolio.fungibleResources.xrdResource.map { token in
				FungibleAssetList.Row.State(xrdToken: token, isSelected: state.mode.xrdRowSelected)
			}
			let nonXrd = portfolio.fungibleResources.nonXrdResources
				.map { token in
					FungibleAssetList.Row.State(
						nonXRDToken: token,
						isSelected: state.mode.nonXrdRowSelected(token.resourceAddress)
					)
				}
			let nfts = portfolio.nonFungibleResources.map { resource in
				NonFungibleAssetList.Row.State(
					resource: resource,
					disabled: state.mode.selectedAssets?.disabledNFTs ?? [],
					selectedAssets: state.mode.nftRowSelectedAssets(resource.resourceAddress)
				)
			}

			state.fungibleTokenList = .init(xrdToken: xrd, nonXrdTokens: .init(uniqueElements: nonXrd))
			state.nonFungibleTokenList = .init(rows: .init(uniqueElements: nfts))

			let lsuResource: PoolUnitsList.LSUResource.State? = { () -> PoolUnitsList.LSUResource.State? in
				guard !portfolio.poolUnitResources.radixNetworkStakes.isEmpty else {
					return nil
				}
				return .init(stakes: portfolio.poolUnitResources.radixNetworkStakes)
			}()

			state.poolUnitsList = .init(
				lsuResource: lsuResource
			)
			return .none
		}
	}
}

extension AssetsView.State {
	/// Computed property of currently selected assets
	public var selectedAssets: Mode.SelectedAssets? {
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
				let selected = $0.resource.tokens.filter { token in selectedAssets.contains(token.id) }

				return Mode.SelectedAssets.NonFungibleTokensPerResource(
					resourceAddress: $0.resource.resourceAddress,
					resourceImage: $0.resource.iconURL,
					resourceName: $0.resource.name,
					tokens: selected
				)
			}
			return nil
		}

		guard fungibleresources.xrdResource != nil || !fungibleresources.nonXrdResources.isEmpty || !nonFungibleResources.isEmpty else {
			return nil
		}

		return .init(
			fungibleResources: fungibleresources,
			nonFungibleResources: IdentifiedArrayOf(uniqueElements: nonFungibleResources),
			disabledNFTs: mode.selectedAssets?.disabledNFTs ?? []
		)
	}

	public var chooseButtonTitle: String {
		guard let selectedAssets else {
			return L10n.AssetTransfer.AddAssets.buttonAssetsNone
		}

		if selectedAssets.assetsCount == 1 {
			return L10n.AssetTransfer.AddAssets.buttonAssetsOne
		}

		return L10n.AssetTransfer.AddAssets.buttonAssets(selectedAssets.assetsCount)
	}
}

// MARK: - AssetsView.State.Mode
extension AssetsView.State {
	public enum Mode: Hashable, Sendable {
		public struct SelectedAssets: Hashable, Sendable {
			public struct NonFungibleTokensPerResource: Hashable, Sendable, Identifiable {
				public var id: ResourceAddress {
					resourceAddress
				}

				public let resourceAddress: ResourceAddress
				public let resourceImage: URL?
				public let resourceName: String?
				public var tokens: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>

				public init(
					resourceAddress: ResourceAddress,
					resourceImage: URL?,
					resourceName: String?,
					tokens: IdentifiedArrayOf<AccountPortfolio.NonFungibleResource.NonFungibleToken>
				) {
					self.resourceAddress = resourceAddress
					self.resourceImage = resourceImage
					self.resourceName = resourceName
					self.tokens = tokens
				}
			}

			public var fungibleResources: AccountPortfolio.FungibleResources
			public var nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource>
			public var disabledNFTs: Set<NonFungibleAssetList.Row.State.AssetID>

			public init(
				fungibleResources: AccountPortfolio.FungibleResources = .init(),
				nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource> = [],
				disabledNFTs: Set<NonFungibleAssetList.Row.State.AssetID>
			) {
				self.fungibleResources = fungibleResources
				self.nonFungibleResources = nonFungibleResources
				self.disabledNFTs = disabledNFTs
			}

			public var assetsCount: Int {
				fungibleResources.nonXrdResources.count +
					nonFungibleResources.map(\.tokens.count).reduce(0, +) +
					(fungibleResources.xrdResource != nil ? 1 : 0)
			}
		}

		case normal
		case selection(SelectedAssets)

		public var selectedAssets: SelectedAssets? {
			switch self {
			case .normal:
				return nil
			case let .selection(assets):
				return assets
			}
		}

		public var isSelection: Bool {
			if case .selection = self {
				return true
			}
			return false
		}

		var xrdRowSelected: Bool? {
			selectedAssets.map { $0.fungibleResources.xrdResource != nil }
		}

		func nonXrdRowSelected(_ resource: ResourceAddress) -> Bool? {
			selectedAssets?.fungibleResources.nonXrdResources.contains { $0.resourceAddress == resource }
		}

		func nftRowSelectedAssets(_ resource: ResourceAddress) -> OrderedSet<NonFungibleAssetList.Row.State.AssetID>? {
			selectedAssets.map { $0.nonFungibleResources[id: resource]?.tokens.ids ?? [] }
		}
	}
}
