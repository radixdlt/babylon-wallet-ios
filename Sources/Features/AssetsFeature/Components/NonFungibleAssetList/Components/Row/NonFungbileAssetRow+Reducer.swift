import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			static let pageSize = OnLedgerEntitiesClient.maximumNFTIDChunkSize

			public var id: ResourceAddress { resource.resourceAddress }
			public typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

			public let resource: OnLedgerEntity.OwnedNonFungibleResource
			public let accountAddress: AccountAddress

			public var tokens: [[Loadable<OnLedgerEntity.NonFungibleToken>]] = []
			public var lastLoadedPageIndex: Int = -1
			public var lastVisibleRowIndex: Int = 0
			public var nextPageCursor: String?
			public var isLoadingResources: Bool = false

			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?

			public init(
				accountAddress: AccountAddress,
				resource: OnLedgerEntity.OwnedNonFungibleResource,
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
			case onTokenDidAppear(index: Int)
		}

		public enum DelegateAction: Sendable, Equatable {
			case open(OnLedgerEntity.NonFungibleToken)
		}

		public enum InternalAction: Sendable, Equatable {
			public struct TokensLoadResult: Sendable, Equatable {
				let tokens: [OnLedgerEntity.NonFungibleToken]
				let nextPageCursor: String?
				let pageIndex: Int
			}

			case tokensLoaded(TaskResult<TokensLoadResult>)
		}

		@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
		@Dependency(\.errorQueue) var errorQueue

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .assetTapped(asset):
				guard !state.disabled.contains(asset.id) else { return .none }

				if state.selectedAssets != nil {
					state.selectedAssets?.toggle(asset)
					return .none
				}
				return .send(.delegate(.open(asset)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				if state.isExpanded {
					let pagesCount = max(state.resource.nonFungibleIdsCount / State.pageSize, 1)
					let remainder = state.resource.nonFungibleIdsCount % State.pageSize
					state.tokens = .init(repeating: .init(repeating: .loading, count: State.pageSize), count: pagesCount)
					if pagesCount > 1, remainder > 0 {
						state.tokens.append(.init(repeating: .loading, count: remainder))
					}
					return loadResources(&state, pageIndex: 0)
				}

				return .none

			case let .onTokenDidAppear(index):
				state.lastVisibleRowIndex = index
				let pageIndex = index / State.pageSize
				if state.isLoadingResources == false, pageIndex > state.lastLoadedPageIndex {
					return loadResources(&state, pageIndex: state.lastLoadedPageIndex + 1)
				}
				return .none
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .tokensLoaded(result):
				switch result {
				case let .success(tokensPage):
					state.nextPageCursor = tokensPage.nextPageCursor
					state.tokens[tokensPage.pageIndex] = tokensPage.tokens.map(Loadable.success)
					state.lastLoadedPageIndex = tokensPage.pageIndex

					if state.lastVisibleRowIndex / State.pageSize > tokensPage.pageIndex {
						return loadResources(&state, pageIndex: tokensPage.pageIndex + 1)
					}

					state.isLoadingResources = false
				case let .failure(err):
					errorQueue.schedule(err)
					state.isLoadingResources = false
				}
				return .none
			}
		}

		func loadResources(_ state: inout State, pageIndex: Int) -> Effect<Action> {
			state.isLoadingResources = true
			let cursor = state.nextPageCursor
			return .run { [resource = state.resource, accountAddress = state.accountAddress] send in
				let result = await TaskResult {
					let data = try await onLedgerEntitiesClient.getAccountOwnedNonFungibleTokenData(.init(accountAddress: accountAddress, resource: resource, mode: .loadPage(pageCursor: cursor)))
					return InternalAction.TokensLoadResult(tokens: data.tokens, nextPageCursor: data.nextPageCursor, pageIndex: pageIndex)
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}
	}
}
