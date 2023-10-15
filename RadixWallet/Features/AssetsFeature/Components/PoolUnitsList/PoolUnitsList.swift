import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?
		var poolUnits: IdentifiedArrayOf<PoolUnit.State> = []
		let account: OnLedgerEntity.Account

		var didLoadResource: Bool {
			if case .success = poolUnits.first?.resourceDetails {
				return true
			}
			return false
		}
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
		case loadedResources(TaskResult<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]>)
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
			guard !state.didLoadResource else {
				return .none
			}
			return getOwnedPoolUnitsDetails(state, refresh: false)

		case .refresh:
			state.poolUnits.forEach { unit in
				state.poolUnits[id: unit.poolUnit.resourcePoolAddress]?.resourceDetails = .loading
			}
			return .run { send in
				await send(.child(.lsuResource(.view(.refresh))))
			}
			.merge(with: getOwnedPoolUnitsDetails(state, refresh: true))
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

	private func getOwnedPoolUnitsDetails(_ state: State, refresh: Bool) -> Effect<Action> {
		let account = state.account
		return .run { send in
			let result = await TaskResult { try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(account, refresh: refresh) }
			await send(.internal(.loadedResources(result)))
		}
	}
}
