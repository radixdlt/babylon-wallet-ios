// MARK: - StakeUnitList
public struct StakeUnitList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let account: OnLedgerEntity.Account
		public var stakeDetails: Loadable<IdentifiedArrayOf<OnLedgerEntitiesClient.OwnedStakeDetails>> = .idle
		var shouldRefresh = false
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case detailsLoaded(TaskResult<[OnLedgerEntitiesClient.OwnedStakeDetails]>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			guard !state.stakeDetails.isSuccess else {
				return .none
			}

			state.stakeDetails = .loading

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
			state.stakeDetails = .success(details.asIdentifiable())

			return .none
		case let .detailsLoaded(.failure(error)):
			state.stakeDetails = .failure(error)
			errorQueue.schedule(error)
			return .none
		}
	}
}

// MARK: - OnLedgerEntitiesClient.OwnedStakeDetails + Identifiable
extension OnLedgerEntitiesClient.OwnedStakeDetails: Identifiable {
	public var id: ValidatorAddress {
		validator.address
	}
}
