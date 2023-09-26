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

		public var fungibleTokenList: FungibleAssetList.State?
		public var nonFungibleTokenList: NonFungibleAssetList.State?
		public var poolUnitsList: PoolUnitsList.State?

		public let account: Profile.Network.Account
		public var isLoadingResources: Bool = false
		public let mode: Mode

		public init(account: Profile.Network.Account, mode: Mode = .normal) {
			self.init(
				account: account,
				fungibleTokenList: nil,
				nonFungibleTokenList: nil,
				poolUnitsList: nil,
				mode: mode
			)
		}

		init(
			account: Profile.Network.Account,
			assetKinds: NonEmpty<[AssetKind]> = .init(rawValue: AssetKind.allCases)!,
			fungibleTokenList: FungibleAssetList.State?,
			nonFungibleTokenList: NonFungibleAssetList.State?,
			poolUnitsList: PoolUnitsList.State?,
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
		case updatePortfolio(AccountPortfolio)
	}

	public enum DelegateAction: Sendable, Equatable {
		case handleSelectedAssets(State.Mode.SelectedAssets)
		case dismiss
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
				FungibleAssetList()
			}
			.ifLet(\.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
				NonFungibleAssetList()
			}
			.ifLet(\.poolUnitsList, action: /Action.child .. ChildAction.poolUnitsList) {
				PoolUnitsList()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.isLoadingResources = true
			return .run { [address = state.account.address] send in
				for try await portfolio in await accountPortfoliosClient.portfolioForAccount(address).debounce(for: .seconds(0.1)) {
					guard !Task.isCancelled else { return }
					await send(.internal(.updatePortfolio(portfolio.nonEmptyVaults)))
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .updatePortfolio(portfolio):
			state.updatePortfolio(to: portfolio)
			state.isLoadingResources = false
			return .none
		}
	}
}

extension AssetsView.State {
	public mutating func updatePortfolio(to portfolio: AccountPortfolio) {
		let xrd = portfolio.fungibleResources.xrdResource.map { token in
			FungibleAssetList.Row.State(
				xrdToken: token,
				isSelected: mode.xrdRowSelected
			)
		}
		let nonXrd = portfolio.fungibleResources.nonXrdResources
			.map { token in
				FungibleAssetList.Row.State(
					nonXRDToken: token,
					isSelected: mode.nonXrdRowSelected(token.resourceAddress)
				)
			}
		let nfts = portfolio.nonFungibleResources.map { resource in
			NonFungibleAssetList.Row.State(
				resource: resource,
				disabled: mode.selectedAssets?.disabledNFTs ?? [],
				selectedAssets: mode.nftRowSelectedAssets(resource.resourceAddress)
			)
		}

		if xrd != nil || !nonXrd.isEmpty {
			fungibleTokenList = .init(xrdToken: xrd, nonXrdTokens: .init(uniqueElements: nonXrd))
		}

		if !nfts.isEmpty {
			nonFungibleTokenList = .init(rows: .init(uniqueElements: nfts))
		}

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
									.flatMap(mode.nonXrdRowSelected),
								selectedStakeClaimAssets: (stake.stakeClaimResource?.resourceAddress)
									.flatMap(mode.nftRowSelectedAssets)
							)
						}
				)
			)
		}()

		if lsuResource != nil || !portfolio.poolUnitResources.poolUnits.isEmpty {
			poolUnitsList = .init(
				lsuResource: lsuResource,
				poolUnits: .init(
					uncheckedUniqueElements: portfolio.poolUnitResources.poolUnits
						.map {
							PoolUnit.State(
								poolUnit: $0,
								isSelected: mode
									.nonXrdRowSelected($0.poolUnitResource.resourceAddress)
							)
						}
				)
			)
		}
	}
}

extension AssetsView.State {
	/// Computed property of currently selected assets
	public var selectedAssets: Mode.SelectedAssets? {
		guard case .selection = mode else { return nil }

		let selectedLsuTokens = poolUnitsList?.lsuResource?.stakes
			.compactMap(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []
		let selectedPoolUnitTokens = poolUnitsList?.poolUnits
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedXRDResource = fungibleTokenList?.xrdToken
			.map(SelectedResourceProvider.init)
			.flatMap(\.selectedResource)

		let selectedNonXrdResources = fungibleTokenList?.nonXrdTokens
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedStakeClaimNonFungibleResources = (poolUnitsList?.lsuResource?.stakes)
			.map { $0.compactMap(NonFungibleTokensPerResourceProvider.init) } ?? []
		let selectedNonFungibleResources = nonFungibleTokenList?.rows.compactMap(NonFungibleTokensPerResourceProvider.init) ?? []

		let selectedFungibleResources = AccountPortfolio.FungibleResources(
			xrdResource: selectedXRDResource,
			nonXrdResources: selectedNonXrdResources + selectedLsuTokens + selectedPoolUnitTokens
		)

		let selectedNonFungibleTokensPerResource = (
			selectedNonFungibleResources + selectedStakeClaimNonFungibleResources
		).compactMap(\.nonFungibleTokensPerResource)

		guard
			selectedFungibleResources.xrdResource != nil
			|| !selectedFungibleResources.nonXrdResources.isEmpty
			|| !selectedNonFungibleTokensPerResource.isEmpty
		else {
			return nil
		}

		return .init(
			fungibleResources: selectedFungibleResources,
			nonFungibleResources: IdentifiedArrayOf(uniqueElements: selectedNonFungibleTokensPerResource),
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
				public var tokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>

				public init(
					resourceAddress: ResourceAddress,
					resourceImage: URL?,
					resourceName: String?,
					tokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken>
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
	let resource: Resource

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

	init?(with lsuStake: LSUStake.State) {
		guard let resource = lsuStake.stake.stakeUnitResource else {
			return nil
		}

		self.init(
			isSelected: lsuStake.isStakeSelected,
			resource: resource
		)
	}

	init(with poolUnit: PoolUnit.State) {
		self.init(
			isSelected: poolUnit.isSelected,
			resource: poolUnit.poolUnit.poolUnitResource
		)
	}
}

// MARK: - NonFungibleTokensPerResourceProvider
private struct NonFungibleTokensPerResourceProvider {
	let selectedAssetIDs: OrderedSet<OnLedgerEntity.NonFungibleToken.ID>?
	let resource: AccountPortfolio.NonFungibleResource?

	var nonFungibleTokensPerResource: AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? {
		selectedAssetIDs.flatMap { selectedStakeClaimAssets -> AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? in
			guard
				let resource,
				!selectedStakeClaimAssets.isEmpty
			else {
				return nil
			}

			return nil

//			let selected = resource.tokens.filter { token in selectedStakeClaimAssets.contains(token.id) }
//
//			return .init(
//				resourceAddress: resource.resourceAddress,
//				resourceImage: resource.iconURL,
//				resourceName: resource.name,
//				tokens: selected
//			)
		}
	}
}

extension NonFungibleTokensPerResourceProvider {
	init(with lsuStake: LSUStake.State) {
		self.init(
			selectedAssetIDs: lsuStake.selectedStakeClaimAssets,
			resource: lsuStake.stake.stakeClaimResource
		)
	}

	init(with row: NonFungibleAssetList.Row.State) {
		self.init(
			selectedAssetIDs: row.selectedAssets,
			resource: row.resource
		)
	}
}
