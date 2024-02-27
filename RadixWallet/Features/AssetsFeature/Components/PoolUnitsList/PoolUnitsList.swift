import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		var poolUnits: IdentifiedArrayOf<ResourceBalance.PoolUnit>
		var selected: [ResourceBalance.PoolUnit.ID: Bool]

		var poolDetailsArray: [OnLedgerEntitiesClient.OwnedResourcePoolDetails] = []

		@PresentationState
		var destination: Destination.State?

		var didLoadResource: Bool {
			if case .success = poolUnits.first?.resources {
				return true
			}
			return false
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case refresh
		case poolUnitWasTapped(ResourceBalance.PoolUnit.ID)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedResources(TaskResult<[OnLedgerEntitiesClient.OwnedResourcePoolDetails]>)
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				PoolUnitDetails()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard !state.didLoadResource else {
				return .none
			}
			return getOwnedPoolUnitsDetails(state, cachingStrategy: .useCache)

		case .refresh:
			for unit in state.poolUnits {
				state.poolUnits[id: unit.resourcePoolAddress]?.resources = .loading
			}
			return getOwnedPoolUnitsDetails(state, cachingStrategy: .forceUpdate)
		case let .poolUnitWasTapped(id):
			if let isSelected = state.selected[id] {
				state.selected[id] = !isSelected
			} else {
				guard let details = state.poolDetailsArray.first(where: { $0.address == id }) else {
					return .none
				}
				state.destination = .details(
					.init(resourcesDetails: details)
				)
			}

			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedResources(.success(poolDetailsArray)):
			state.poolDetailsArray = poolDetailsArray

			for poolDetails in poolDetailsArray {
				state.poolUnits[id: poolDetails.address]?.resources = .success(.init(resources: poolDetails))
				state.poolUnits[id: poolDetails.address]?.dAppName = .success(poolDetails.dAppName)
			}
			return .none
		case .loadedResources:
			return .none
		}
	}

	private func getOwnedPoolUnitsDetails(
		_ state: State,
		cachingStrategy: OnLedgerEntitiesClient.CachingStrategy
	) -> Effect<Action> {
		let account = state.account
		return .run { send in
			let result = await TaskResult {
				try await onLedgerEntitiesClient.getOwnedPoolUnitsDetails(
					account,
					cachingStrategy: cachingStrategy
				)
			}
			await send(.internal(.loadedResources(result)))
		}
	}
}
