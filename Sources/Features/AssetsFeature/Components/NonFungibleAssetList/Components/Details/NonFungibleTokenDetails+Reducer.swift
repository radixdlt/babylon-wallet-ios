import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let resourceAddress: ResourceAddress
		public var resource: Loadable<OnLedgerEntity.Resource>
		public let prefetchedPortfolioResource: AccountPortfolio.NonFungibleResource?
		public let token: OnLedgerEntity.NonFungibleToken?

		public init(
			resourceAddress: ResourceAddress,
			resource: Loadable<OnLedgerEntity.Resource> = .idle,
			prefetchedPortfolioResource: AccountPortfolio.NonFungibleResource? = nil,
			token: OnLedgerEntity.NonFungibleToken? = nil
		) {
			self.resourceAddress = resourceAddress
			self.resource = resource
			self.token = token
			self.prefetchedPortfolioResource = prefetchedPortfolioResource
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceLoadResult(TaskResult<OnLedgerEntity.Resource>)
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			state.resource = .loading
			return .run { [resourceAddress = state.resourceAddress] send in
				try await Task.sleep(for: .seconds(3))
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddress) }
				await send(.internal(.resourceLoadResult(result)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceLoadResult(.success(resource)):
			state.resource = .success(resource)
			return .none
		case let .resourceLoadResult(.failure(err)):
			state.resource = .failure(err)
			return .none
		}
	}
}
