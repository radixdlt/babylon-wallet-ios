import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

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
		public struct ResourcesState: Sendable, Equatable {
			public let fungibleTokenList: FungibleAssetList.State?
			public let nonFungibleTokenList: NonFungibleAssetList.State?
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
					await send(.internal(.resourcesStateUpdated(createResourcesState(from: portfolio.nonEmptyVaults, mode: mode))))
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
		case let .resourcesStateUpdated(resourcesState):
			state.isLoadingResources = false
			state.fungibleTokenList = resourcesState.fungibleTokenList
			state.nonFungibleTokenList = resourcesState.nonFungibleTokenList
			state.poolUnitsList = resourcesState.poolUnitsList
			return .none
		}
	}

	private func createResourcesState(from portfolio: AccountPortfolio, mode: State.Mode) async -> InternalAction.ResourcesState {
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
				accountAddress: portfolio.owner,
				resource: resource,
				disabled: mode.selectedAssets?.disabledNFTs ?? [],
				selectedAssets: mode.nftRowSelectedAssets(resource.resourceAddress)
			)
		}
		let poolUnits = await createPoolUnitsState(from: portfolio, mode: mode)
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

		return .init(
			fungibleTokenList: fungibleTokenList,
			nonFungibleTokenList: !nfts.isEmpty ? .init(rows: .init(uniqueElements: nfts)) : nil,
			poolUnitsList: poolUnits
		)
	}

	private func createPoolUnitsState(from portfolio: AccountPortfolio, mode: State.Mode) async -> PoolUnitsList.State? {
		let stakeUnitResources = portfolio.poolUnitResources.radixNetworkStakes.compactMap {
			$0.stakeUnitResource?.resourceAddress
		}
		let stakeClaimNfts = portfolio.poolUnitResources.radixNetworkStakes
			.compactMap(\.stakeClaimResource)
			.filter { $0.nonFungibleIdsCount > 0 }

		let poolResources = portfolio.poolUnitResources.poolUnits.flatMap {
			$0.poolResources.nonXrdResources.map(\.resourceAddress) + ($0.poolResources.xrdResource.map { [$0.resourceAddress] } ?? [])
		}
		let poolUnitResources = portfolio.poolUnitResources.poolUnits.map(\.poolUnitResource.resourceAddress)

		let allResourceAddresses = stakeUnitResources + poolResources + poolUnitResources + stakeClaimNfts.map(\.resourceAddress)

		let resources: [OnLedgerEntity.Resource]
		let nftClaimTokens: [OnLedgerEntity.NonFungibleToken]

		do {
			// If failure, don't show any Pool Units.
			resources = try await onLedgerEntitiesClient.getResources(allResourceAddresses)
			nftClaimTokens = []
			//            try await stakeClaimNfts.parallelMap {
//				try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
//					atLedgerState: $0.atLedgerState,
//					resource: $0.resourceAddress,
//					nonFungibleIds: $0.nonFungibleIds
//				))
//			}
			//            .flatMap(identity)
		} catch {
			// throw error
			return nil
		}

		// populate everything needed here
		let stakes = portfolio.poolUnitResources.radixNetworkStakes.map {
			let stakeResource = $0.stakeUnitResource.flatMap { resource in resources.first(where: { $0.resourceAddress == resource.resourceAddress }) }
			let stakeClaimNFTResource = $0.stakeClaimResource.flatMap { resource in resources.first(where: { $0.resourceAddress == resource.resourceAddress }) }
			let stakeClaimNFTS = $0.stakeClaimResource.map { resource in
				nftClaimTokens.filter { $0.id.resourceAddress().asStr() == resource.resourceAddress.address }
			} ?? []
			return LSUStake.State(stake: $0, stakeResource: stakeResource, stakeClaimNFTResource: stakeClaimNFTResource, stakeClaimNfts: stakeClaimNFTS)
		}

		let pools: [PoolUnit.State] = portfolio.poolUnitResources.poolUnits.compactMap { poolUnit in
			let poolUnitResource = resources.first { resource in resource.resourceAddress == poolUnit.poolUnitResource.resourceAddress }
			let poolResources = resources.filter { resource in
				let unitResources = poolUnit.poolResources.nonXrdResources.map(\.resourceAddress) + (poolUnit.poolResources.xrdResource.map { [$0.resourceAddress] } ?? [])
				return unitResources.contains { $0 == resource.resourceAddress }
			}

			guard let poolUnitResource, !poolResources.isEmpty else {
				assertionFailure("Bad implementation, didn't get the resources for the pool unit")
				return nil
			}
			return PoolUnit.State(poolUnit: poolUnit, poolUnitResource: poolUnitResource, poolResources: poolResources)
		}

		let lsuResource: LSUResource.State? = LSUResource.State(stakes: .init(uncheckedUniqueElements: stakes))

		if lsuResource != nil || !portfolio.poolUnitResources.poolUnits.isEmpty {
			return .init(
				lsuResource: lsuResource,
				poolUnits: .init(uncheckedUniqueElements: pools)
			)
		}

		return nil
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

		let selectedXRDResource = fungibleTokenList?.sections[id: .xrd]?
			.rows
			.first
			.map(SelectedResourceProvider.init)
			.flatMap(\.selectedResource)

		let selectedNonXrdResources = fungibleTokenList?.sections[id: .nonXrd]?.rows
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

extension SelectedResourceProvider<AccountPortfolio.FungibleResource> {
	init(with row: FungibleAssetList.Section.Row.State) {
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
	let selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
	let resource: AccountPortfolio.NonFungibleResource?

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
				resourceName: resource.metadata.name,
				tokens: [] // .init(uncheckedUniqueElements: selected.elements)
			)
		}
	}
}

extension NonFungibleTokensPerResourceProvider {
	init(with lsuStake: LSUStake.State) {
		self.init(
			selectedAssets: lsuStake.selectedStakeClaimAssets,
			resource: lsuStake.stake.stakeClaimResource
		)
	}

	init(with row: NonFungibleAssetList.Row.State) {
		self.init(
			selectedAssets: row.selectedAssets,
			resource: row.resource
		)
	}
}

extension Array where Element: Identifiable {
	func asIdentifiable() -> IdentifiedArrayOf<Element> {
		var array: IdentifiedArrayOf<Element> = []
		array.append(contentsOf: self)
		return array
	}
}
