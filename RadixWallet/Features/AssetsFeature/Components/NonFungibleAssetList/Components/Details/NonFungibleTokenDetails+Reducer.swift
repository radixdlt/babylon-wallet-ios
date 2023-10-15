import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let resourceAddress: ResourceAddress
		public var resourceDetails: Loadable<OnLedgerEntity.Resource>
		public let ownedResource: OnLedgerEntity.OwnedNonFungibleResource?
		public let token: OnLedgerEntity.NonFungibleToken?
		public let ledgerState: AtLedgerState

		public init(
			resourceAddress: ResourceAddress,
			resourceDetails: Loadable<OnLedgerEntity.Resource> = .idle,
			ownedResource: OnLedgerEntity.OwnedNonFungibleResource? = nil,
			token: OnLedgerEntity.NonFungibleToken? = nil,
			ledgerState: AtLedgerState
		) {
			self.resourceAddress = resourceAddress
			self.resourceDetails = resourceDetails
			self.token = token
			self.ownedResource = ownedResource
			self.ledgerState = ledgerState
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case task
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			guard case .idle = state.resourceDetails else {
				return .none
			}
			state.resourceDetails = .loading
			return .run { [resourceAddress = state.resourceAddress, ledgerState = state.ledgerState] send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddress, atLedgerState: ledgerState) }
				await send(.internal(.resourceLoadResult(result)))
			}
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoadResult(.success(resource)):
			state.resourceDetails = .success(resource)
			return .none
		case let .resourceLoadResult(.failure(err)):
			state.resourceDetails = .failure(err)
			return .none
		}
	}
}
