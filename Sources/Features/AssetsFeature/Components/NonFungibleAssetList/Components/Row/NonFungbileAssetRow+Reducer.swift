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
			public var tokens: [Loadable<OnLedgerEntity.NonFungibleToken>] = []
			public var nextPageCursor: String?
			public var isLoadingResources: Bool = false
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<OnLedgerEntity.NonFungibleToken>?
			public var lastVisibleRowIndex: Int = 0

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
				let pageIndex: Int
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
				if state.isExpanded {
					state.tokens = .init(repeating: .loading, count: state.resource.nonFungibleIdsCount)
				}
				return loadResources(&state, pageIndex: 0)

			case let .onTokenDidAppear(index):
				state.lastVisibleRowIndex = index

				if state.isLoadingResources == false {
					return loadResources(&state, pageIndex: 0)
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
					let totalIdsCount = state.resource.nonFungibleIdsCount
					let pageSize = State.pageSize
					let pageIndex = tokensPage.pageIndex

					let rangeOrigin = tokensPage.pageIndex * State.pageSize

					var rangeLength: Int = {
						if totalIdsCount < State.pageSize {
							return totalIdsCount
						}

						return min(totalIdsCount - rangeOrigin, State.pageSize)
					}()

					state.tokens.replaceSubrange(
						rangeOrigin ..< (rangeOrigin + rangeLength),
						with: tokensPage.tokens.map(Loadable.success)
					)

					if state.lastVisibleRowIndex / State.pageSize > pageIndex {
						return loadResources(&state, pageIndex: pageIndex + 1)
					}

					state.isLoadingResources = false
//					state.loadedTokens.append(contentsOf: tokensPage.tokens)
//					state.nextPageCursor = tokensPage.nextPageCursor
				case let .failure(err):
					break
				}
				return .none
			}
		}

		func loadResources(_ state: inout State, pageIndex: Int) -> Effect<Action> {
			guard !state.isLoadingResources, state.loadedTokens.count < state.resource.nonFungibleIdsCount else {
				return .none
			}

			print("Loading resources")

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

					return InternalAction.TokensLoadResult(tokens: data, nextPageCursor: idsPage.nextPageCursor, pageIndex: pageIndex)
				}
				await send(.internal(.tokensLoaded(result)))
			}
		}
	}
}
