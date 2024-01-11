import ComposableArchitecture
import SwiftUI

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			static let pageSize = OnLedgerEntitiesClient.maximumNFTIDChunkSize

			public var id: ResourceAddress { resource.resourceAddress }
			public typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

			public let resource: OnLedgerEntity.OwnedNonFungibleResource
			public let accountAddress: AccountAddress

			/// The loaded pages of tokens
			public var tokens: [[Loadable<OnLedgerEntity.NonFungibleToken>]] = []
			/// Last page index that was loaded, useful to determin the next page index that needs to be loaded
			public var lastLoadedPageIndex: Int = -1
			/// The last visible row to which user scrolled to, will be used to proactively fetch additional pages
			/// if user did scroll past currently loading page
			public var lastVisibleRowIndex: Int = 0
			/// Tokens pages are loaded one after another, in order to load the next page we need to have
			/// the nextPageCursor received after loading current page.
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
					if state.resource.nonFungibleIdsCount < State.pageSize {
						state.tokens = [.init(repeating: .loading, count: state.resource.nonFungibleIdsCount)]
					} else {
						/// The total number of full pages
						let fullPagesCount = state.resource.nonFungibleIdsCount / State.pageSize
						/// Prepopulate with placeholders
						state.tokens = .init(repeating: .init(repeating: .loading, count: State.pageSize), count: fullPagesCount)
						/// The number of items to add to the last page
						let remainder = state.resource.nonFungibleIdsCount % State.pageSize
						if fullPagesCount > 0, remainder > 0 {
							/// At last page placeholders also
							state.tokens.append(.init(repeating: .loading, count: remainder))
						}
					}
					return loadResources(&state, pageIndex: 0)
				}

				return .none

			case let .onTokenDidAppear(index):
				state.lastVisibleRowIndex = index
				let rowPageIndex = index / State.pageSize
				/// Load next page if not currently loading and current page was not loaded.
				if state.isLoadingResources == false, rowPageIndex > state.lastLoadedPageIndex {
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

					/// If user did quick scroll over the currently loading page, proactively load the next page.
					/// If there are 5 pages in total, and user did scroll fast to last one, this will load all pages in chain, one after another.
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
