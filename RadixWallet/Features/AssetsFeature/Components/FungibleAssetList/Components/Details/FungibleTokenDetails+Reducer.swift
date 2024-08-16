import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resourceAddress: ResourceAddress
		var resource: Loadable<OnLedgerEntity.Resource>
		let isXRD: Bool
		let ownedFungibleResource: OnLedgerEntity.OwnedFungibleResource?
		let ledgerState: AtLedgerState?
		var hideAsset: HideAsset.State

		public init(
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
			self.hideAsset = .init(asset: .fungible(resourceAddress))
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case hideAsset(HideAsset.Action)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.hideAsset, action: \.child.hideAsset) {
			HideAsset()
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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
}
