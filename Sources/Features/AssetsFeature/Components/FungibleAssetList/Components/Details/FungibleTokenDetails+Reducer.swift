import FeaturePrelude
import OnLedgerEntitiesClient
import SharedModels

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let resourceAddress: ResourceAddress
		var resource: Loadable<OnLedgerEntity.Resource>
		let isXRD: Bool
		let prefetchedPortfolioResource: AccountPortfolio.FungibleResource?

		public init(
			resourceAddress: ResourceAddress,
			resource: Loadable<OnLedgerEntity.Resource> = .idle,
			prefetchedPortfolioResource: AccountPortfolio.FungibleResource? = nil,
			isXRD: Bool
		) {
			self.resourceAddress = resourceAddress
			self.resource = resource
			self.prefetchedPortfolioResource = prefetchedPortfolioResource
			self.isXRD = isXRD
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
			guard case .idle = state.resource else {
				return .none
			}
			state.resource = .loading
			return .run { [resourceAddress = state.resourceAddress] send in
				try await Task.sleep(for: .seconds(3))
				let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddress) }
				await send(.internal(.resourceLoadResult(result)))
			}
		case .closeButtonTapped:
			return .send(.delegate(.dismiss))
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

// MARK: - ResourceDetails
public struct ResourceDetails: Sendable {
	public struct State: Sendable, Hashable {
		enum PortfolioResource: Sendable, Hashable {
			case fungible(AccountPortfolio.FungibleResource, isXRD: Bool)
			case nonFungible(AccountPortfolio.NonFungibleResource)
		}

		let prefetchedPortfolioResource: PortfolioResource?
		let resource: Loadable<OnLedgerEntity.Resource>
	}
}
