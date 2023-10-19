import ComposableArchitecture
import SwiftUI

// MARK: - LSUResource
public struct LSUResource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isExpanded: Bool = false

		let account: OnLedgerEntity.Account
		var stakes: IdentifiedArrayOf<LSUStake.State>
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
		case isExpandedToggled
		case refresh
	}

	public enum ChildAction: Sendable, Equatable {
		case stake(id: LSUStake.State.ID, action: LSUStake.Action)
	}

	public enum InternalAction: Sendable, Equatable {
		case detailsLoaded(TaskResult<[OnLedgerEntitiesClient.OwnedStakeDetails]>)
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
			if state.isExpanded {
				guard !state.didLoadResources, !state.isLoadingResources else {
					return .none
				}
				return .run { [state = state] send in
					let result = await TaskResult {
						try await onLedgerEntitiesClient.getOwnedStakesDetails(
							account: state.account,
							refresh: state.shouldRefresh
						)
					}
					await send(.internal(.detailsLoaded(result)))
				}
			}
			return .none
		case .refresh:
			state.shouldRefresh = true
			state.stakes.forEach { stake in
				state.stakes[id: stake.id]?.stakeDetails = .loading
			}
			return .none
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
			state.isExpanded = false
			errorQueue.schedule(error)
			return .none
		}
	}
}
