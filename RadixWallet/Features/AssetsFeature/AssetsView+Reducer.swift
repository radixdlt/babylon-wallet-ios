import ComposableArchitecture
import SwiftUI

// MARK: - AssetsView
public struct AssetsView: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// All of the possible asset list
		public enum AssetKind: String, Sendable, Hashable, CaseIterable, Identifiable {
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

		public var activeAssetKind: AssetKind
		public var assetKinds: NonEmpty<[AssetKind]>

		public var fungibleTokenList: FungibleAssetList.State?
		public var nonFungibleTokenList: NonFungibleAssetList.State?
		public var stakeUnitList: StakeUnitList.State?
		public var poolUnitsList: PoolUnitsList.State?

		public let account: Profile.Network.Account
		public var isLoadingResources: Bool = false
		public var isRefreshing: Bool = false
		public let mode: Mode

		public init(account: Profile.Network.Account, mode: Mode = .normal) {
			self.init(
				account: account,
				fungibleTokenList: nil,
				nonFungibleTokenList: nil,
				stakeUnitList: nil,
				poolUnitsList: nil,
				mode: mode
			)
		}

		init(
			account: Profile.Network.Account,
			assetKinds: NonEmpty<[AssetKind]> = .init(rawValue: AssetKind.allCases)!,
			fungibleTokenList: FungibleAssetList.State?,
			nonFungibleTokenList: NonFungibleAssetList.State?,
			stakeUnitList: StakeUnitList.State?,
			poolUnitsList: PoolUnitsList.State?,
			mode: Mode
		) {
			self.account = account
			self.assetKinds = assetKinds
			self.activeAssetKind = assetKinds.first
			self.fungibleTokenList = fungibleTokenList
			self.nonFungibleTokenList = nonFungibleTokenList
			self.stakeUnitList = stakeUnitList
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

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case fungibleTokenList(FungibleAssetList.Action)
		case nonFungibleTokenList(NonFungibleAssetList.Action)
		case stakeUnitList(StakeUnitList.Action)
		case poolUnitsList(PoolUnitsList.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		public struct ResourcesState: Sendable, Equatable {
			public let fungibleTokenList: FungibleAssetList.State?
			public let nonFungibleTokenList: NonFungibleAssetList.State?
			public let stakeUnitList: StakeUnitList.State?
			public let poolUnitsList: PoolUnitsList.State?
		}

		case resourcesStateUpdated(ResourcesState)
	}

	public enum DelegateAction: Sendable, Equatable {
		case handleSelectedAssets(State.Mode.SelectedAssets)
		case dismiss
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.fungibleTokenList, action: /Action.child .. ChildAction.fungibleTokenList) {
				FungibleAssetList()
			}
			.ifLet(\.nonFungibleTokenList, action: /Action.child .. ChildAction.nonFungibleTokenList) {
				NonFungibleAssetList()
			}
			.ifLet(\.stakeUnitList, action: /Action.child .. ChildAction.stakeUnitList) {
				StakeUnitList()
			}
			.ifLet(\.poolUnitsList, action: /Action.child .. ChildAction.poolUnitsList) {
				PoolUnitsList()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.isLoadingResources = true
			return .run { [address = state.account.address, mode = state.mode] send in
				for try await portfolio in await accountPortfoliosClient.portfolioForAccount(address).debounce(for: .seconds(0.1)) {
					guard !Task.isCancelled else { return }

					await send(.internal(.resourcesStateUpdated(createResourcesState(
						from: portfolio.nonEmptyVaults,
						mode: mode
					)
					)))
				}
			} catch: { error, _ in
				loggerGlobal.error("AssetsView portfolioForAccount failed: \(error)")
			}
		case let .didSelectList(kind):
			state.activeAssetKind = kind
			return .none
		case .pullToRefreshStarted:
			state.isRefreshing = true
			return .run { [address = state.account.address] _ in
				_ = try await accountPortfoliosClient.fetchAccountPortfolio(address, true)
			} catch: { error, _ in
				loggerGlobal.error("AssetsView fetch failed: \(error)")
			}
		case let .chooseButtonTapped(items):
			return .send(.delegate(.handleSelectedAssets(items)))
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourcesStateUpdated(resourcesState):
			state.isLoadingResources = false
			state.fungibleTokenList = resourcesState.fungibleTokenList
			state.nonFungibleTokenList = resourcesState.nonFungibleTokenList
			state.stakeUnitList = resourcesState.stakeUnitList
			state.poolUnitsList = resourcesState.poolUnitsList

			state.isRefreshing = false

			let shouldRefreshPoolUnitList = resourcesState.poolUnitsList != nil
				&& (state.activeAssetKind == .poolUnits || state.isRefreshing)

			let shouldRefreshStakeUnitList = resourcesState.stakeUnitList != nil
				&& (state.activeAssetKind == .stakeUnits || state.isRefreshing)

			return .run { send in
				if shouldRefreshPoolUnitList {
					await send(.child(.poolUnitsList(.view(.refresh))))
				}
				if shouldRefreshStakeUnitList {
					await send(.child(.stakeUnitList(.view(.refresh))))
				}
			}
		}
	}

	private func createResourcesState(
		from portfolio: OnLedgerEntity.Account,
		mode: State.Mode
	) async -> InternalAction.ResourcesState {
		let xrd = portfolio.fungibleResources.xrdResource.map { token in
			FungibleAssetList.Section.Row.State(
				xrdToken: token,
				isSelected: mode.xrdRowSelected
			)
		}
		let nonXrd = portfolio.fungibleResources.nonXrdResources
			.map { token in
				FungibleAssetList.Section.Row.State(
					nonXRDToken: token,
					isSelected: mode.nonXrdRowSelected(token.resourceAddress)
				)
			}
			.asIdentifiable()

		let nfts = portfolio.nonFungibleResources.map { resource in
			NonFungibleAssetList.Row.State(
				accountAddress: portfolio.address,
				resource: resource,
				disabled: mode.selectedAssets?.disabledNFTs ?? [],
				selectedAssets: mode.nftRowSelectedAssets(resource.resourceAddress)
			)
		}

		let poolUnitList: PoolUnitsList.State? = {
			guard !portfolio.poolUnitResources.poolUnits.isEmpty else {
				return nil
			}

			let poolUnits = portfolio.poolUnitResources.poolUnits.map {
				PoolUnitsList.State.PoolUnitState(
					poolUnit: $0,
					isSelected: mode.nonXrdRowSelected($0.resource.resourceAddress)
				)
			}

			return .init(
				account: portfolio,
				poolUnits: .init(uncheckedUniqueElements: poolUnits)
			)
		}()

		let fungibleTokenList: FungibleAssetList.State? = {
			var sections: IdentifiedArrayOf<FungibleAssetList.Section.State> = []
			if let xrd {
				sections.append(.init(id: .xrd, rows: [xrd]))
			}

			if !nonXrd.isEmpty {
				sections.append(.init(id: .nonXrd, rows: nonXrd))
			}

			guard !sections.isEmpty else {
				return nil
			}

			return .init(sections: sections)
		}()

		let stakes = portfolio.poolUnitResources.radixNetworkStakes
		let stakeUnitList: StakeUnitList.State? = stakes.isEmpty ? nil : .init(
			account: portfolio,
			selectedLiquidStakeUnits: mode.selectedAssets.map { assets in
				let stakeUnitResources = stakes.map(\.stakeUnitResource)
				return assets
					.fungibleResources
					.nonXrdResources
					.filter(stakeUnitResources.contains)
					.asIdentifiable()
			},
			selectedStakeClaimTokens:
			mode.isSelection ?
				stakes
				.compactMap(\.stakeClaimResource)
				.reduce(into: StakeUnitList.SelectedStakeClaimTokens()) { dict, resource in
					if let selectedtokens = mode.nftRowSelectedAssets(resource.resourceAddress)?.elements.asIdentifiable() {
						dict[resource] = selectedtokens
					}
				} : nil
		)

		return .init(
			fungibleTokenList: fungibleTokenList,
			nonFungibleTokenList: !nfts.isEmpty ? .init(rows: .init(uniqueElements: nfts)) : nil,
			stakeUnitList: stakeUnitList,
			poolUnitsList: poolUnitList
		)
	}
}

extension AssetsView.State {
	/// Computed property of currently selected assets
	public var selectedAssets: Mode.SelectedAssets? {
		guard case .selection = mode else { return nil }

		let selectedLiquidStakeUnits = stakeUnitList?.selectedLiquidStakeUnits ?? []

		let selectedPoolUnitTokens = poolUnitsList?.poolUnits
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedXRDResource = fungibleTokenList?.sections[id: .xrd]?
			.rows
			.first
			.map(SelectedResourceProvider.init)
			.flatMap(\.selectedResource)

		let selectedNonXrdResources = fungibleTokenList?.sections[id: .nonXrd]?.rows
			.map(SelectedResourceProvider.init)
			.compactMap(\.selectedResource) ?? []

		let selectedNonFungibleResources = nonFungibleTokenList?.rows.compactMap(NonFungibleTokensPerResourceProvider.init) ?? []
		let selectedStakeClaims = stakeUnitList?.selectedStakeClaimTokens?.map { resource, tokens in
			NonFungibleTokensPerResourceProvider(selectedAssets: .init(tokens), resource: resource)
		} ?? []

		let selectedFungibleResources = OnLedgerEntity.OwnedFungibleResources(
			xrdResource: selectedXRDResource,
			nonXrdResources: selectedNonXrdResources + selectedLiquidStakeUnits + selectedPoolUnitTokens
		)

		let selectedNonFungibleTokensPerResource =
			(selectedNonFungibleResources + selectedStakeClaims)
				.compactMap(\.nonFungibleTokensPerResource)

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

			public var fungibleResources: OnLedgerEntity.OwnedFungibleResources
			public var nonFungibleResources: IdentifiedArrayOf<NonFungibleTokensPerResource>
			public var disabledNFTs: Set<NonFungibleAssetList.Row.State.AssetID>

			public init(
				fungibleResources: OnLedgerEntity.OwnedFungibleResources = .init(),
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
				nil
			case let .selection(assets):
				assets
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

		func nftRowSelectedAssets(_ resource: ResourceAddress) -> OrderedSet<OnLedgerEntity.NonFungibleToken>? {
			selectedAssets.map { OrderedSet($0.nonFungibleResources[id: resource]?.tokens.elements ?? []) }
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

extension SelectedResourceProvider<OnLedgerEntity.OwnedFungibleResource> {
	init(with row: FungibleAssetList.Section.Row.State) {
		self.init(
			isSelected: row.isSelected,
			resource: row.token
		)
	}

	init(with poolUnit: PoolUnitsList.State.PoolUnitState) {
		self.init(
			isSelected: poolUnit.isSelected,
			resource: poolUnit.poolUnit.resource
		)
	}
}

// MARK: - NonFungibleTokensPerResourceProvider
private struct NonFungibleTokensPerResourceProvider {
	let selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
	let resource: OnLedgerEntity.OwnedNonFungibleResource?

	var nonFungibleTokensPerResource: AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? {
		selectedAssets.flatMap { selectedAssets -> AssetsView.State.Mode.SelectedAssets.NonFungibleTokensPerResource? in
			guard
				let resource,
				!selectedAssets.isEmpty
			else {
				return nil
			}

//			let selected = selectedAssets.filter {
//				resource.nonFungibleIds.contains($0.id)
//			}
			// resource.tokens.filter { token in selectedStakeClaimAssets.contains(token.id) }

			return .init(
				resourceAddress: resource.resourceAddress,
				resourceImage: resource.metadata.iconURL,
				resourceName: resource.metadata.title,
				tokens: .init(uncheckedUniqueElements: selectedAssets)
			)
		}
	}
}

extension NonFungibleTokensPerResourceProvider {
	init(with row: NonFungibleAssetList.Row.State) {
		self.init(
			selectedAssets: row.selectedAssets,
			resource: row.resource
		)
	}
}
