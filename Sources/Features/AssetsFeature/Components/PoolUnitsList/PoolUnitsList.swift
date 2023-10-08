import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?
		var poolUnits: IdentifiedArrayOf<PoolUnit.State> = []
	}

	public enum ChildAction: Sendable, Equatable {
		case lsuResource(LSUResource.Action)
		case poolUnit(id: PoolUnit.State.ID, action: PoolUnit.Action)
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case refresh
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedResources(TaskResult<[OnLedgerEntity.ResourcePoolDetails]>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(
				\.lsuResource,
				action: /Action.child .. ChildAction.lsuResource,
				then: LSUResource.init
			)
			.forEach(
				\.poolUnits,
				action: /Action.child .. ChildAction.poolUnit,
				element: PoolUnit.init
			)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			let ownedPoolUnits = state.poolUnits.map(\.poolUnit)
			return .run { send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getPoolUnitsDetail(ownedPoolUnits) }
				await send(.internal(.loadedResources(result)))
			}
		case .refresh:
			return .none
//			print("refresh")
			//            let addresses = state.poolUnits.first?.poolUnit.resource.resourceAddress ?? []
//			return .run { send in
//				let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
//				await send(.internal(.loadedResources(result)))
//			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedResources(.success(poolDetails)):
			poolDetails.forEach { poolDetails in
				state.poolUnits[id: poolDetails.address]?.resourceDetails = .success(poolDetails)
			}
			return .none
		case .loadedResources:
			return .none
		}
	}
}
