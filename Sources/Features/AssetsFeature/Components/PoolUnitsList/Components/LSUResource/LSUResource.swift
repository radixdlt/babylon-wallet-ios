import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - LSUResource
public struct LSUResource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isExpanded: Bool = false

		let stakess: [OnLedgerEntity.Account.RadixNetworkStake]
		let account: OnLedgerEntity.Account
		var stakes: IdentifiedArrayOf<LSUStake.State>

		var isLoadingResources = false
	}

	public enum ViewAction: Sendable, Equatable {
		case isExpandedToggled
	}

	public enum ChildAction: Sendable, Equatable {
		case stake(id: LSUStake.State.ID, action: LSUStake.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case detailsLoaded(TaskResult<[OnLedgerEntity.ValidatorDetails]>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

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
		case .isExpandedToggled:
			state.isExpanded.toggle()
			state.stakes = state.stakess.map {
				LSUStake.State(validatorAddress: $0.validatorAddress, stakeDetails: .loading)
			}.asIdentifiable()
			state.isLoadingResources = true
			return .run { [state = state] send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getValidatorsDetails(account: state.account, state.stakess) }
				await send(.internal(.detailsLoaded(result)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .detailsLoaded(.success(details)):
			state.isLoadingResources = false
			details.forEach { details in
				state.stakes[id: details.validator.address.address]?.stakeDetails = .success(details)
			}
			return .none
		case let .detailsLoaded(.failure(error)):
			state.isLoadingResources = false
			state.isExpanded = false
			errorQueue.schedule(error)
			return .none
		}
	}
}
