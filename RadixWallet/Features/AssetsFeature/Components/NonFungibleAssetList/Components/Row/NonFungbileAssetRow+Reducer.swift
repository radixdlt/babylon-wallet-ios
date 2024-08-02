import ComposableArchitecture
import SwiftUI

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			static let pageSize = OnLedgerEntitiesClient.maximumNFTIDChunkSize

			public var id: ResourceAddress { resource.resourceAddress }
			public typealias AssetID = OnLedgerEntity.NonFungibleToken.ID

			public var resource: OnLedgerEntity.OwnedNonFungibleResource
			public let accountAddress: AccountAddress

			/// The loaded tokens
			public var tokens: [Loadable<OnLedgerEntity.NonFungibleToken>] = []
			/// Last token index that was loaded, useful to determin the next page index that needs to be loaded
			public var lastLoadedTokenIndex: Int = 0
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
				let previousTokenIndex: Int
			}

			case tokensLoaded(TaskResult<TokensLoadResult>)
			case refreshResources
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
					state.lastLoadedTokenIndex = 0
					setTokensPlaceholders(&state)
					print("M- is expanded")
					return loadResources(&state, previousTokenIndex: 0)
				}

				return .none

			case let .onTokenDidAppear(index):
				state.lastVisibleRowIndex = index
				/// Load next page if not currently loading and current page was not loaded.
				if state.isLoadingResources == false, index > state.lastLoadedTokenIndex, state.nextPageCursor != nil {
					print("M- on token did appear, row: \(index), last: \(state.lastLoadedTokenIndex)")
					return loadResources(&state, previousTokenIndex: state.lastLoadedTokenIndex)
				}
				return .none
			}
		}

		public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .tokensLoaded(result):
				switch result {
				case let .success(tokensPage):
					print("M- TokensPage: \(tokensPage.previousTokenIndex)")
					state.nextPageCursor = tokensPage.nextPageCursor
					let success = tokensPage.tokens.map(Loadable.success)
					state.tokens[tokensPage.previousTokenIndex ..< tokensPage.previousTokenIndex + success.count] = success[0 ..< success.count]
					state.lastLoadedTokenIndex = max(state.lastLoadedTokenIndex, tokensPage.previousTokenIndex + success.count)

					/// If user did quick scroll over the currently loading page, proactively load the next page.
					/// If there are 5 pages in total, and user did scroll fast to last one, this will load all pages in chain, one after another.
					if state.lastVisibleRowIndex - State.pageSize + 2 > state.lastLoadedTokenIndex {
						return loadResources(&state, previousTokenIndex: state.lastLoadedTokenIndex)
					}

					state.isLoadingResources = false
				case let .failure(err):
					errorQueue.schedule(err)
					state.isLoadingResources = false
				}
				return .none

			case .refreshResources:
				state.nextPageCursor = nil
				setTokensPlaceholders(&state)
				print("M- refresh resources")
				return loadResources(&state, previousTokenIndex: 0)
			}
		}

		private func loadResources(_ state: inout State, previousTokenIndex: Int) -> Effect<Action> {
			let cursor = state.nextPageCursor
			print("M- Will load previous \(previousTokenIndex), cursor \(cursor ?? "nil"), isLoading: \(state.isLoadingResources)")
			state.isLoadingResources = true
			return .run { [resource = state.resource, accountAddress = state.accountAddress] send in
				let result = await TaskResult {
					let data = try await onLedgerEntitiesClient.getAccountOwnedNonFungibleTokenData(.init(accountAddress: accountAddress, resource: resource, mode: .loadPage(pageCursor: cursor)))
					return InternalAction.TokensLoadResult(tokens: data.tokens, nextPageCursor: data.nextPageCursor, previousTokenIndex: previousTokenIndex)
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}

		private func setTokensPlaceholders(_ state: inout State) {
			state.tokens = .init(repeating: .loading, count: state.resource.nonFungibleIdsCount)
		}
	}
}
