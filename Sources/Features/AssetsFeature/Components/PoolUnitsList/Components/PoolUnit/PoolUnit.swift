import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - PoolUnit
public struct PoolUnit: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: ResourcePoolAddress {
			poolUnit.poolAddress
		}

		let poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit
		var loadedPoolResources: Loadable<[OnLedgerEntity.Resource]> = .idle
		var isSelected: Bool?

		@PresentationState
		var destination: Destinations.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case didTap
		case task
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case resourcesLoadedResult(TaskResult<[OnLedgerEntity.Resource]>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case details(PoolUnitDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(PoolUnitDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(
				state: /State.details,
				action: /Action.details,
				child: PoolUnitDetails.init
			)
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(
				\.$destination,
				action: /Action.child .. ChildAction.destination,
				destination: Destinations.init
			)
	}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard case .idle = state.loadedPoolResources else {
				return .none
			}

			state.loadedPoolResources = .loading
			let addresses = [state.poolUnit.poolUnitResource.resourceAddress] +
				(state.poolUnit.poolResources.xrdResource.map { [$0.resourceAddress] } ?? []) +
				state.poolUnit.poolResources.nonXrdResources.map(\.resourceAddress)

			return .run { send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
				await send(.internal(.resourcesLoadedResult(result)))
			}
		case .didTap:
			if state.isSelected != nil {
				state.isSelected?.toggle()
			} else {
				state.destination = .details(
					.init(poolUnit: state.poolUnit, loadedPoolResources: state.loadedPoolResources)
				)
			}

			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourcesLoadedResult(.success(resources)):
			state.loadedPoolResources = .success(resources)
			return .none
		case let .resourcesLoadedResult(.failure(err)):
			state.loadedPoolResources = .failure(err)
			return .none
		}
	}
}
