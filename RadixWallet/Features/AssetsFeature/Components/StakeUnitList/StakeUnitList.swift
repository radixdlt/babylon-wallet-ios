// MARK: - StakeUnitList

public struct StakeUnitList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		public var stakes: IdentifiedArrayOf<LSUStake.State>
		var isLoadingResources: Bool = false
		var shouldRefresh = false

		var didLoadResources: Bool {
			if case .success = stakes.first?.stakeDetails {
				return true
			}
			return false
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum ChildAction: Sendable, Equatable {
		case stake(id: LSUStake.State.ID, action: LSUStake.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case detailsLoaded(TaskResult<[OnLedgerEntitiesClient.OwnedStakeDetails]>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(
				\.stakes,
				action: /Action.child .. ChildAction.stake,
				element: LSUStake.init
			)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			guard !state.didLoadResources, !state.isLoadingResources else {
				return .none
			}
			return .run { [state = state] send in
				let result = await TaskResult {
					try await onLedgerEntitiesClient.getOwnedStakesDetails(
						account: state.account,
						cachingStrategy: state.shouldRefresh ? .forceUpdate : .useCache
					)
				}
				await send(.internal(.detailsLoaded(result)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .detailsLoaded(.success(details)):
			state.shouldRefresh = false
			state.isLoadingResources = false
			details.forEach { details in
				state.stakes[id: details.validator.address.address]?.stakeDetails = .success(details)
			}
			return .none
		case let .detailsLoaded(.failure(error)):
			state.isLoadingResources = false
			errorQueue.schedule(error)
			return .none
		}
	}
}
