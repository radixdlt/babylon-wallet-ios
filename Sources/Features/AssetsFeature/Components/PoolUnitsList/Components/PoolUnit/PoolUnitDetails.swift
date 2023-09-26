import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - PoolUnitDetails
public struct PoolUnitDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit
		var loadedPoolResources: Loadable<[OnLedgerEntity.Resource]>

		public init(
			poolUnit: AccountPortfolio.PoolUnitResources.PoolUnit,
			loadedPoolResources: Loadable<[OnLedgerEntity.Resource]> = .idle
		) {
			self.poolUnit = poolUnit
			self.loadedPoolResources = loadedPoolResources
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
	}

	public enum InternalAction: Sendable, Equatable {
		case resourcesLoadedResult(TaskResult<[OnLedgerEntity.Resource]>)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
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
