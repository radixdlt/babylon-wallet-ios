import ComposableArchitecture

// MARK: - HiddenAssets
@Reducer
public struct HiddenAssets: Sendable, FeatureReducer {
	@ObservableState
	public struct State: Sendable, Hashable {
		var fungible: [OnLedgerEntity.Resource] = []
		var nonFungible: [OnLedgerEntity.Resource] = []
		var poolUnit: [State.PoolUnitDetails] = []

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
		case unhideTapped(ResourceIdentifier)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadResources([ResourceIdentifier])
		case setFungible([OnLedgerEntity.Resource])
		case setNonFungible([OnLedgerEntity.Resource])
		case setPoolUnit([State.PoolUnitDetails])
		case didUnhideResource(ResourceIdentifier)
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
				case confirmTapped(ResourceIdentifier)
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	@Dependency(\.resourcesVisibilityClient) var resourcesVisibilityClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.accountsClient) var accountsClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				let hiddenResources = try await resourcesVisibilityClient.getHidden()
				await send(.internal(.loadResources(hiddenResources)))
			}
		case let .unhideTapped(resource):
			state.destination = .unhideAlert(.init(
				title: { TextState(resource.unhideAlertTitle) },
				actions: {
					ButtonState(role: .cancel, action: .cancelTapped) {
						TextState(L10n.Common.cancel)
					}
					ButtonState(action: .confirmTapped(resource)) {
						TextState(L10n.Common.confirm)
					}
				}
			))
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadResources(hiddenResources):
			return fungibleEffect(hiddenResources: hiddenResources)
				.merge(with: nonFungibleEffect(hiddenResources: hiddenResources))
				.merge(with: poolUnitEffect(hiddenResources: hiddenResources))

		case let .setFungible(values):
			state.fungible = values
			return .none

		case let .setNonFungible(values):
			state.nonFungible = values
			return .none

		case let .setPoolUnit(values):
			state.poolUnit = values
			return .none

		case let .didUnhideResource(resource):
			switch resource {
			case let .fungible(resourceAddress):
				state.fungible.removeAll(where: { $0.resourceAddress == resourceAddress })
			case let .nonFungible(resourceAddress):
				state.nonFungible.removeAll(where: { $0.resourceAddress == resourceAddress })
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
			case let .confirmTapped(resource):
				return .run { send in
					try await resourcesVisibilityClient.unhide(resource)
					await send(.internal(.didUnhideResource(resource)), animation: .default)
				}
			case .cancelTapped:
				state.destination = nil
				return .none
			}
		}
	}

	private func fungibleEffect(hiddenResources: [ResourceIdentifier]) -> Effect<Action> {
		.run { send in
			let resources = try await onLedgerEntitiesClient.getEntities(addresses: hiddenResources.fungibleAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resource)
			await send(.internal(.setFungible(resources)))
		}
	}

	private func nonFungibleEffect(hiddenResources: [ResourceIdentifier]) -> Effect<Action> {
		.run { send in
			let resources = try await onLedgerEntitiesClient.getEntities(addresses: hiddenResources.nonFungibleAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resource)
			await send(.internal(.setNonFungible(resources)))
		}
	}

	private func poolUnitEffect(hiddenResources: [ResourceIdentifier]) -> Effect<Action> {
		.run { send in
			let resourcePools = try await onLedgerEntitiesClient.getEntities(addresses: hiddenResources.poolUnitAddresses, metadataKeys: .resourceMetadataKeys).compactMap(\.resourcePool)
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

private extension [ResourceIdentifier] {
	var fungibleAddresses: [Address] {
		compactMap { item in
			guard case let .fungible(resourceAddress) = item else {
				return nil
			}
			return resourceAddress.asGeneral
		}
	}

	var nonFungibleAddresses: [Address] {
		compactMap { item in
			guard case let .nonFungible(resourceAddress) = item else {
				return nil
			}
			return resourceAddress.asGeneral
		}
	}

	var poolUnitAddresses: [Address] {
		compactMap { item in
			guard case let .poolUnit(poolAddress) = item else {
				return nil
			}
			return poolAddress.asGeneral
		}
	}
}

private extension ResourceIdentifier {
	var unhideAlertTitle: String {
		switch self {
		case .fungible, .poolUnit:
			L10n.HiddenAssets.UnhideConfirmation.asset
		case .nonFungible:
			L10n.HiddenAssets.UnhideConfirmation.collection
		}
	}
}
