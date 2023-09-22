import EngineKit
import FeaturePrelude
import OnLedgerEntitiesClient

extension NonFungibleAssetList {
	public struct Row: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public var id: ResourceAddress { resource.resourceAddress }
			public typealias AssetID = AccountPortfolio.NonFungibleResource.NonFungibleToken.ID

			public let resource: AccountPortfolio.NonFungibleResource
			public var loadedTokens: IdentifiedArrayOf<OnLedgerEntity.NonFungibleToken> = []
			public var loadedPages: Int = 0
			public var isLoadingResources: Bool = true
			public var isExpanded = false
			public var disabled: Set<AssetID> = []
			public var selectedAssets: OrderedSet<AssetID>?

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
				return .run { [resource = state.resource] send in
					let result = await TaskResult {
						try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
							atLedgerState: resource.atLedgerState,
							resource: resource.resourceAddress,
							nonFungibleIds: Array(resource.tokens.prefix(10))
						)
						)
					}
					await send(.internal(.tokensLoaded(result)))
				}
			case .didAppear:
				return .send(.delegate(.didAppear(state.resource.resourceAddress)))

			case let .assetTapped(localID):
				guard !state.disabled.contains(localID) else { return .none }
				guard let token = state.loadedTokens[id: localID] else {
					loggerGlobal.warning("Selected a missing token")
					return .none
				}
				if state.selectedAssets != nil {
//					guard let token = state.resource.tokens[id: localID] else {
//						loggerGlobal.warning("Selected a missing token")
//						return .none
//					}
//					state.selectedAssets?.toggle(token.id)
					return .none
				}
				return .send(.delegate(.open(token)))

			case .isExpandedToggled:
				state.isExpanded.toggle()
				return .run { [resource = state.resource] send in
					let result = await TaskResult {
						try await onLedgerEntitiesClient.getNonFungibleTokenData(.init(
							atLedgerState: resource.atLedgerState,
							resource: resource.resourceAddress,
							nonFungibleIds: Array(resource.tokens.prefix(10))
						)
						)
					}
					await send(.internal(.tokensLoaded(result)))
				}
			case let .onTokenDidAppear(index: index):
				// is Last
				guard index == (state.loadedTokens.count - 1) else {
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

		func loadResources(_ state: inout State) -> Effect<Action> {
			guard !state.isLoadingResources, state.loadedTokens.count < state.resource.tokens.count else {
				return .none
			}

			loggerGlobal.error("Loading tokens \(state.loadedTokens.count) vs \(state.resource.tokens.count)")

			let pageSize = 7

			let diff = state.resource.tokens.count - state.loadedTokens.count
			let tokens = {
				if diff < pageSize {
					return state.resource.tokens.suffix(diff)
				}
				let pageStartIndex = state.loadedTokens.count
				return state.resource.tokens[pageStartIndex ..< pageStartIndex + pageSize]
			}()

			let pageIndex = state.loadedPages + 1

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
