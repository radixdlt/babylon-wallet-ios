import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenDetails
@Reducer
struct FungibleTokenDetails: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let resourceAddress: ResourceAddress
		var resource: Loadable<OnLedgerEntity.Resource>
		let isXRD: Bool
		let ownedFungibleResource: OnLedgerEntity.OwnedFungibleResource?
		let ledgerState: AtLedgerState?
		var hideResource: HideResource.State

		init(
			resourceAddress: ResourceAddress,
			resource: Loadable<OnLedgerEntity.Resource> = .idle,
			ownedFungibleResource: OnLedgerEntity.OwnedFungibleResource? = nil,
			isXRD: Bool,
			ledgerState: AtLedgerState? = nil
		) {
			self.resourceAddress = resourceAddress
			self.resource = resource
			self.ownedFungibleResource = ownedFungibleResource
			self.isXRD = isXRD
			self.ledgerState = ledgerState
			self.hideResource = .init(kind: .fungible(resourceAddress))
		}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
	}

	enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case hideResource(HideResource.Action)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.hideResource, action: \.child.hideResource) {
			HideResource()
		}

		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard case .idle = state.resource else {
				return .none
			}
			state.resource = .loading
			return .run { [resourceAddress = state.resourceAddress, ledgerState = state.ledgerState] send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddress, atLedgerState: ledgerState, fetchMetadata: true) }
				await send(.internal(.resourceLoadResult(result)))
			}
		case .closeButtonTapped:
			return .run { _ in await dismiss() }
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoadResult(.success(resource)):
			state.resource = .success(resource)
			return .none
		case let .resourceLoadResult(.failure(error)):
			state.resource = .failure(error)
			errorQueue.schedule(error)
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .hideResource(.delegate(.didHideResource)):
			.run { _ in await dismiss() }
		default:
			.none
		}
	}
}
