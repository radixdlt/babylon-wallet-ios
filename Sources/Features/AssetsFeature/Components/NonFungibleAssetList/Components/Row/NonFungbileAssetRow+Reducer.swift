import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			static let pageSize = OnLedgerEntitiesClient.maximumNFTIDChunkSize

			public var id: ResourceAddress { resource.resourceAddress }
			public typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

			public let resource: AccountPortfolio.NonFungibleResource
			public var loadedTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> = []
			public var loadedPages: Int = 0
			public var isLoadingResources: Bool = true
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?

			public init(
				resource: AccountPortfolio.NonFungibleResource,
				disabled: Set<AssetID> = [],
				selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
			) {
				self.resource = resource
				self.disabled = disabled
				self.selectedAssets = selectedAssets
			}
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
			case assetTapped(OnLedgerEntity.NonFungibleToken)
			case didAppear
			case task
			case onTokenDidAppear(index: Int)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(OnLedgerEntity.NonFungibleToken)
			case didAppear(ResourceAddress)
		}

		public enum InternalAction: Sendable, Equatable {
			case tokensLoaded(TaskResult<[OnLedgerEntity.NonFungibleToken]>)
		}

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				return .none
			case .didAppear:
				return .send(.delegate(.didAppear(state.resource.resourceAddress)))

			case let .assetTapped(asset):
				guard !state.disabled.contains(asset.id) else { return .none }

				if state.selectedAssets != nil {
					state.selectedAssets?.toggle(asset)
					return .none
				}
				return .send(.delegate(.open(asset)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				guard state.isExpanded, state.loadedTokens.isEmpty else {
					return .none
				}
				return fetchTokens(
					for: state.resource,
					Array(state.resource.nonFungibleIds.prefix(2 * State.pageSize))
				)
			case let .onTokenDidAppear(index: index):
				guard index == state.loadedTokens.count - State.pageSize else {
					return .none
				}

				return loadResources(&state)
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .tokensLoaded(result):
				state.isLoadingResources = false
				switch result {
				case let .success(tokens):
					state.loadedTokens.append(contentsOf: tokens)
				case let .failure(err):
					break
				}
				return .none
			}
		}

		private func fetchTokens(for resource: AccountPortfolio.NonFungibleResource, _ ids: [NonFungibleGlobalId]) -> Effect<Action> {
			.run { send in
				let result = await TaskResult {
					try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
						atLedgerState: resource.atLedgerState,
						resource: resource.resourceAddress,
						nonFungibleIds: ids
					))
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}

		func loadResources(_ state: inout State) -> Effect<Action> {
			let diff = state.resource.nonFungibleIds.count - state.loadedTokens.count
			guard !state.isLoadingResources, diff > 0 else {
				return .none
			}

			let tokens = {
				if diff < State.pageSize {
					return state.resource.nonFungibleIds.suffix(diff)
				}
				let pageStartIndex = state.loadedTokens.count
				return state.resource.nonFungibleIds[pageStartIndex ..< pageStartIndex + State.pageSize]
			}()

			state.isLoadingResources = true
			return .run { [resource = state.resource] send in
				let result = await TaskResult {
					try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
						atLedgerState: resource.atLedgerState,
						resource: resource.resourceAddress,
						nonFungibleIds: Array(tokens)
					))
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}
	}
}
