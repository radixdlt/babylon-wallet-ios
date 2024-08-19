import ComposableArchitecture

// MARK: - HiddenAssets
@Reducer
public struct HiddenAssets: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		var fungible: [OnLedgerEntity.Resource] = []
		var nonFungible: [OnLedgerEntity.NonFungibleToken] = []
		var poolUnit: [OnLedgerEntity.ResourcePool] = []
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
		case setPoolUnit([OnLedgerEntity.ResourcePool])
	}

	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			.run { send in
				let hiddenAssets = await appPreferencesClient.getPreferences().assets.hiddenAssets
				await send(.internal(.loadAssets(hiddenAssets)))
			}
		case .unhideTapped:
			.none
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
			let resources = try await onLedgerEntitiesClient.getEntities(addresses: hiddenAssets.poolUnitAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resourcePool)
			await send(.internal(.setPoolUnit(resources)))
		}
	}
}

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
