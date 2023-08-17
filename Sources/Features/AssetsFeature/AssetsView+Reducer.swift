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
				poolUnitsList: .init(),
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
				FungibleAssetList.Row.State(
					xrdToken: token,
					isSelected: state.mode.xrdRowSelected
				)
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

			let lsuResource: LSUResource.State? = {
				guard !portfolio.poolUnitResources.radixNetworkStakes.isEmpty else {
					return nil
				}
				return .init(
					stakes: .init(
						uniqueElements: portfolio.poolUnitResources.radixNetworkStakes
							.map { stake in
								LSUStake.State(
									stake: stake,
									isStakeSelected: (stake.stakeUnitResource?.resourceAddress)
										.flatMap(state.mode.nonXrdRowSelected),
									selectedStakeClaimAssets: (stake.stakeClaimResource?.resourceAddress)
										.flatMap(state.mode.nftRowSelectedAssets)
								)
							}
					)
				)
			}()

			state.poolUnitsList = .init(
				lsuResource: lsuResource,
				poolUnits: .init(
					uncheckedUniqueElements: portfolio.poolUnitResources.poolUnits
						.map {
							PoolUnit.State(
								poolUnit: $0,
								isSelected: state.mode
									.nonXrdRowSelected($0.poolUnitResource.resourceAddress)
							)
						}
				)
			)
			return .none
		}
	}
}

extension AssetsView.State {
	/// Computed property of currently selected assets
	public var selectedAssets: Mode.SelectedAssets? {
		guard case .selection = mode else { return nil }

		let lsuTokens = poolUnitsList.lsuResource?.stakes
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []
		let poolUnitTokens = poolUnitsList.poolUnits
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource)
		let fungibleResources = AccountPortfolio.FungibleResources(
			xrdResource: fungibleTokenList.xrdToken
				.map(SelectedResourceProvider.init)
				.flatMap(\.selectedResource),
			nonXrdResources: fungibleTokenList.nonXrdTokens
				.map(SelectedResourceProvider.init)
				.compactMap(\.selectedResource)
				+ lsuTokens
				+ poolUnitTokens
		)

		let stakeClaimNonFungibleResources = (poolUnitsList.lsuResource?.stakes)
			.map { stakes in
				stakes.compactMap { stake in
					guard
						let resource = stake.stake.stakeClaimResource,
						let selectedAssets = stake.selectedStakeClaimAssets,
						!selectedAssets.isEmpty
					else {
						return Mode.SelectedAssets.NonFungibleTokensPerResource?.none
					}
					let selected = resource.tokens.filter { token in selectedAssets.contains(token.id) }

					return Mode.SelectedAssets.NonFungibleTokensPerResource(
						resourceAddress: resource.resourceAddress,
						resourceImage: resource.iconURL,
						resourceName: resource.name,
						tokens: selected
					)
				}
			}
		let nonFungibleResources = nonFungibleTokenList.rows.compactMap { row in
			if
				let selectedAssets = row.selectedAssets,
				!selectedAssets.isEmpty
			{
				let resource = row.resource
				let selected = resource.tokens.filter { token in selectedAssets.contains(token.id) }

				return Mode.SelectedAssets.NonFungibleTokensPerResource(
					resourceAddress: resource.resourceAddress,
					resourceImage: resource.iconURL,
					resourceName: resource.name,
					tokens: selected
				)
			}
			return nil
		} + (stakeClaimNonFungibleResources ?? [])

		guard
			fungibleResources.xrdResource != nil
			|| !fungibleResources.nonXrdResources.isEmpty
			|| !nonFungibleResources.isEmpty
		else {
			return nil
		}

		return .init(
			fungibleResources: fungibleResources,
			nonFungibleResources: IdentifiedArrayOf(
				uniqueElements: nonFungibleResources
			),
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

// MARK: - SelectedResourceProvider
private struct SelectedResourceProvider<Resource> {
	let isSelected: Bool?
	let resource: Resource?

	var selectedResource: Resource? {
		isSelected.flatMap { $0 ? resource : nil }
	}
}

extension SelectedResourceProvider<AccountPortfolio.FungibleResource> {
	init(with row: FungibleAssetList.Row.State) {
		self.init(
			isSelected: row.isSelected,
			resource: row.token
		)
	}

	init(with lsuStake: LSUStake.State) {
		self.init(
			isSelected: lsuStake.isStakeSelected,
			resource: lsuStake.stake.stakeUnitResource
		)
	}

	init(with poolUnit: PoolUnit.State) {
		self.init(
			isSelected: poolUnit.isSelected,
			resource: poolUnit.poolUnit.poolUnitResource
		)
	}
}
