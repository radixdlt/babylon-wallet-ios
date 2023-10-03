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
			public let accountAddress: AccountAddress
			public var loadedTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> = []
			public var nextPageCursor: String?
			public var isLoadingResources: Bool = false
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?

			public init(
				accountAddress: AccountAddress,
				resource: AccountPortfolio.NonFungibleResource,
				disabled: Set<AssetID> = [],
				selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
			) {
				self.accountAddress = accountAddress
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
			public struct TokensLoadResult: Sendable, Equatable {
				let tokens: [OnLedgerEntity.NonFungibleToken]
				let nextPageCursor: String?
			}

			case tokensLoaded(TaskResult<TokensLoadResult>)
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

				return loadResources(&state)

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
				case let .success(tokensPage):
					state.loadedTokens.append(contentsOf: tokensPage.tokens)
					state.nextPageCursor = tokensPage.nextPageCursor
				case let .failure(err):
					break
				}
				return .none
			}
		}

		func loadResources(_ state: inout State) -> Effect<Action> {
			guard !state.isLoadingResources, state.loadedTokens.count < state.resource.nonFungibleIdsCount else {
				return .none
			}

			state.isLoadingResources = true
			let cursor = state.nextPageCursor
			return .run { [resource = state.resource, accountAddress = state.accountAddress] send in
				let result = await TaskResult {
					let idsPage = try await onLedgerEntitiesClient.getNonFungibleResourceIds(.init(
						account: accountAddress,
						resourceAddress: resource.resourceAddress,
						vaultAddress: resource.vaultAddress,
						atLedgerState: resource.atLedgerState,
						pageCursor: cursor
					))

					let data = try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
						atLedgerState: resource.atLedgerState,
						resource: resource.resourceAddress,
						nonFungibleIds: Array(idsPage.ids)
					))

					return InternalAction.TokensLoadResult(tokens: data, nextPageCursor: idsPage.nextPageCursor)
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}
	}
}
