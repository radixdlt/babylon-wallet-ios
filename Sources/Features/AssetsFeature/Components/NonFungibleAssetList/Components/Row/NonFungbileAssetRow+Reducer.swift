import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }

			public typealias AssetID = AccountPortfolio.NonFungibleResource.NonFungibleToken.ID

			public let resource: AccountPortfolio.NonFungibleResource
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<AssetID>?

			public var resourceDetails: Loadable<OnLedgerEntity.Resource> = .idle

			public init(
				resource: AccountPortfolio.NonFungibleResource,
				disabled: Set<AssetID> = [],
				selectedAssets: OrderedSet<AssetID>?
			) {
				self.resource = resource
				self.disabled = disabled
				self.selectedAssets = selectedAssets
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			case assetTapped(State.AssetID)
			case task
		}

		public enum InternalAction: Sendable, Equatable {
			case resourceDetailsLoaded(TaskResult<OnLedgerEntity.Resource>)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(NonFungibleGlobalId)
		}

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				state.resourceDetails = .loading
				return .run { [resourceAddres = state.resource.resource.resourceAddress] send in
					let result = await TaskResult { try await onLedgerEntitiesClient.getResource(resourceAddres) }
					await send(.internal(.resourceDetailsLoaded(result)))
				}
			case let .assetTapped(localID):
				guard !state.disabled.contains(localID) else { return .none }
				if state.selectedAssets != nil {
//					guard let token = state.resource.tokens[id: localID] else {
//						loggerGlobal.warning("Selected a missing token")
//						return .none
//					}
//					state.selectedAssets?.toggle(token.id)
					return .none
				}
				return .send(.delegate(.open(localID)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				return .none
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .resourceDetailsLoaded(.success(resource)):
				state.resourceDetails = .success(resource)
				return .none
			case let .resourceDetailsLoaded(.failure(err)):
				state.resourceDetails = .failure(err)
				return .none
			}
		}
	}
}
