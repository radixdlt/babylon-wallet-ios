import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		var poolUnits: IdentifiedArrayOf<PoolUnitState>

		@PresentationState
		var destination: Destination.State?

		var didLoadResource: Bool {
			if case .success = poolUnits.first?.resourceDetails {
				return true
			}
			return false
		}

		public struct PoolUnitState: Sendable, Hashable, Identifiable {
			public var id: ResourcePoolAddress { poolUnit.resourcePoolAddress }
			public let poolUnit: OnLedgerEntity.Account.PoolUnit
			public var resourceDetails: Loadable<OnLedgerEntitiesClient.OwnedResourcePoolDetails> = .idle
			public var isSelected: Bool? = nil
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
			for poolUnit in state.poolUnits {
				state.poolUnits[id: poolUnit.id]?.resourceDetails = .loading
			}
			return getOwnedPoolUnitsDetails(state, cachingStrategy: .forceUpdate)
		case let .poolUnitWasTapped(id):
			if let isSelected = state.poolUnits[id: id]?.isSelected {
				state.poolUnits[id: id]?.isSelected = !isSelected
			} else {
				guard let poolUnit = state.poolUnits[id: id], case let .success(details) = poolUnit.resourceDetails else {
					return .none
				}
				state.destination = .details(.init(resourcesDetails: details))
			}

			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedResources(.success(poolDetails)):
			for details in poolDetails {
				state.poolUnits[id: details.address]?.resourceDetails = .success(details)
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
