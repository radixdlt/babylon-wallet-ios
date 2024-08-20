import ComposableArchitecture

// MARK: - HiddenAssets
@Reducer
public struct HiddenAssets: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		var fungible: [OnLedgerEntity.Resource] = []
		var nonFungible: [OnLedgerEntity.NonFungibleToken] = []
		var poolUnit: [PoolUnitDetails] = []

		@Presents
		var destination: Destination.State? = nil

		public struct PoolUnitDetails: Sendable, Hashable {
			let resource: OnLedgerEntity.Resource
			let details: OnLedgerEntitiesClient.OwnedResourcePoolDetails
		}
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Sendable, Equatable {
		case task
		case unhideTapped(AssetAddress)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadAssets([AssetAddress])
		case setFungible([OnLedgerEntity.Resource])
		case setNonFungible([OnLedgerEntity.NonFungibleToken])
		case setPoolUnit([State.PoolUnitDetails])
		case didUnhideAsset(AssetAddress)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case unhideAlert(AlertState<Action.UnhideAlert>)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case unhideAlert(UnhideAlert)

			public enum UnhideAlert: Hashable, Sendable {
				case confirmTapped(AssetAddress)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let hiddenAssets = await appPreferencesClient.getHiddenAssets()
				await send(.internal(.loadAssets(hiddenAssets)))
			}
		case let .unhideTapped(asset):
			state.destination = .unhideAlert(.init(
				title: { TextState(L10n.HiddenAssets.unhideConfirmation) },
				actions: {
					ButtonState(role: .cancel, action: .cancelTapped) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .confirmTapped(asset)) {
						TextState(L10n.Common.confirm)
					}
				}
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadAssets(hiddenAssets):
			return fungibleEffect(hiddenAssets: hiddenAssets)
				.merge(with: nonFungibleEffect(hiddenAssets: hiddenAssets))
				.merge(with: poolUnitEffect(hiddenAssets: hiddenAssets))

		case let .setFungible(values):
			state.fungible = values
			return .none

		case let .setNonFungible(values):
			state.nonFungible = values
			return .none

		case let .setPoolUnit(values):
			state.poolUnit = values
			return .none

		case let .didUnhideAsset(asset):
			switch asset {
			case let .fungible(resourceAddress):
				state.fungible.removeAll(where: { $0.resourceAddress == resourceAddress })
			case let .nonFungible(globalId):
				state.nonFungible.removeAll(where: { $0.id == globalId })
			case let .poolUnit(poolAddress):
				state.poolUnit.removeAll(where: { $0.details.address == poolAddress })
			}
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .unhideAlert(action):
			switch action {
			case let .confirmTapped(asset):
				return .run { send in
					try await appPreferencesClient.updating { preferences in
						preferences.assets.unhideAsset(asset: asset)
					}
					await send(.internal(.didUnhideAsset(asset)), animation: .default)
				}
			case .cancelTapped:
				state.destination = nil
				return .none
			}
		}
	}

	private func fungibleEffect(hiddenAssets: [AssetAddress]) -> Effect<Action> {
		.run { send in
			let resources = try await onLedgerEntitiesClient.getEntities(addresses: hiddenAssets.fungibleAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resource)
			await send(.internal(.setFungible(resources)))
		}
	}

	private func nonFungibleEffect(hiddenAssets: [AssetAddress]) -> Effect<Action> {
		.run { send in
			let tokens = try await hiddenAssets.nonFungibleDictionary.parallelMap { resource, nonFungibleIds in
				try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(resource: resource, nonFungibleIds: nonFungibleIds))
			}
			.flatMap { $0 }
			.sorted(by: \.id.resourceAddress.address)
			await send(.internal(.setNonFungible(tokens)))
		}
	}

	private func poolUnitEffect(hiddenAssets: [AssetAddress]) -> Effect<Action> {
		.run { send in
			let resourcePools = try await onLedgerEntitiesClient.getEntities(addresses: hiddenAssets.poolUnitAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resourcePool)
			let resources = try await resourcePools.parallelMap {
				try await onLedgerEntitiesClient.getResource($0.poolUnitResourceAddress)
			}
			let poolUnitDetails = try await resources.parallelMap { resource in
				if let details = try await onLedgerEntitiesClient.getPoolUnitDetails(resource, forAmount: .one) {
					State.PoolUnitDetails(resource: resource, details: details)
				} else {
					nil
				}
			}
			.compactMap { $0 }
			await send(.internal(.setPoolUnit(poolUnitDetails)))
		}
	}
}

// MARK: - Helpers

private extension [AssetAddress] {
	var fungibleAddresses: [Address] {
		compactMap { item in
			switch item {
			case let .fungible(resourceAddress):
				resourceAddress.asGeneral
			case .nonFungible, .poolUnit:
				nil
			}
		}
	}

	var nonFungibleDictionary: [ResourceAddress: [NonFungibleGlobalId]] {
		let nonFungibleIds = self.compactMap { item in
			switch item {
			case let .nonFungible(id):
				id
			case .fungible, .poolUnit:
				nil
			}
		}
		return Dictionary(grouping: nonFungibleIds) {
			$0.resourceAddress
		}
	}

	var poolUnitAddresses: [Address] {
		compactMap { item in
			switch item {
			case let .poolUnit(poolAddress):
				poolAddress.asGeneral
			case .fungible, .nonFungible:
				nil
			}
		}
	}
}
