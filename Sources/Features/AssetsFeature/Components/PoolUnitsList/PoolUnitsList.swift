import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?
		let pageSize = 5

		var poolUnits: IdentifiedArrayOf<PoolUnit.State> = []

		var scrollIndex: Int = 0
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
		case loadedResources(TaskResult<[OnLedgerEntity.Resource]>)
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
			return .none
		//            let addresses = Array(state.poolUnits.map(\.poolUnit.resource.resourceAddress).uniqued())
//			return .run { send in
//				let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
//				await send(.internal(.loadedResources(result)))
//			}
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
		case let .loadedResources(.success(resources)):
//			state.poolUnits.forEach { poolUnit in
			//                let poolUnitResourceAddress = poolUnit.poolUnit.resource.resourceAddress
//				let poolUnitResource = resources.first { $0.resourceAddress == poolUnitResourceAddress }
//				let xrdResource = resources.first { $0.resourceAddress == poolUnit.poolUnit.poolResources.xrdResource?.resourceAddress }
//				let nonXrdResources = poolUnit.poolUnit.poolResources.nonXrdResources.map { resource in
//					resources.first { $0.resourceAddress == resource.resourceAddress }!
//				}
//
//				state.poolUnits[id: poolUnit.id]?.resourceDetails = .success(.init(poolUnitResource: poolUnitResource!, xrdResource: xrdResource, nonXrdResources: nonXrdResources))
//			}
			return .none
		case .loadedResources:
			return .none
		}
	}
}

// extension OnLedgerEntity.ResourcePool {
//	var resourceAddresses: [ResourceAddress] {
//		(poolResources.xrdResource.map { [$0.resourceAddress] } ?? []) +
//			poolResources.nonXrdResources.map(\.resourceAddress) +
//			[poolUnitResource.resourceAddress]
//	}
// }
