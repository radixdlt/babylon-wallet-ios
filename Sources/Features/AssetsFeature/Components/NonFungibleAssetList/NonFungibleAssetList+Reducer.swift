import FeaturePrelude
import OnLedgerEntitiesClient

// MARK: - NonFungibleAssetList
public struct NonFungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State> = []

		public let resources: AccountPortfolio.NonFungibleResources

		@PresentationState
		public var destination: Destinations.State?
		public var isLoadingResources: Bool = true

		public init(resources: AccountPortfolio.NonFungibleResources) {
			self.resources = resources
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeDetailsTapped
		case task
	}

	public enum ChildAction: Sendable, Equatable {
		case asset(NonFungibleAssetList.Row.State.ID, NonFungibleAssetList.Row.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum InternalAction: Sendable, Equatable {
		case resourceDetailsLoaded(TaskResult<[OnLedgerEntity.Resource]>)
	}

	public struct Destinations: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case details(NonFungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(NonFungibleTokenDetails.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				NonFungibleTokenDetails()
			}
		}
	}

	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.rows, action: /Action.child .. ChildAction.asset) {
				NonFungibleAssetList.Row()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			let addresses = state.resources.prefix(7).map(\.resourceAddress)
			return .run { send in
				let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
				await send(.internal(.resourceDetailsLoaded(result)))
			}

		case .closeDetailsTapped:
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .resourceDetailsLoaded(result):
			state.isLoadingResources = false
			switch result {
			case let .success(loadedResources):
				do {
					let newResources = try loadedResources.map { loadedResource in
						guard let resource = state.resources.first(where: { $0.resourceAddress == loadedResource.resourceAddress }) else {
							// Should not happen, but still
							struct InvalidLoad: Error {}
							throw InvalidLoad()
						}

						return NonFungibleAssetList.Row.State(resource: .init(resource: loadedResource, tokens: resource.tokens, atLedgerState: resource.atLedgerState), selectedAssets: [])
					}
					state.rows.append(contentsOf: newResources)
				} catch {
					// throw error
					return .none
				}
				return .none

			case let .failure(error):
				return .none
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .asset(rowID, .delegate(.open(token))):
			guard let row = state.rows[id: rowID] else {
				loggerGlobal.warning("Selected row does not exist \(rowID)")
				return .none
			}

			//	state.destination = .details(.init(resource: row.resource.resource, token: token))
			return .none

		case let .asset(rowID, .delegate(.didAppear)):
			guard state.rows.last?.id == rowID else {
				return .none
			}

			return loadResources(&state)

		case .asset:
			return .none

		case .destination:
			return .none
		}
	}

	func loadResources(_ state: inout State) -> Effect<Action> {
		guard !state.isLoadingResources, state.rows.count < state.resources.count else {
			return .none
		}

		let pageSize = 7

		let diff = state.resources.count - state.rows.count
		let resourcess = {
			if diff < pageSize {
				return state.resources.suffix(diff)
			}
			let pageStartIndex = state.resources.count + 1
			return state.resources[pageStartIndex ..< pageStartIndex + pageSize]
		}()

		let addresses = resourcess.map(\.resource.resourceAddress)
		state.isLoadingResources = true
		return .run { send in
			let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
			await send(.internal(.resourceDetailsLoaded(result)))
		}
	}
}

// MARK: - PaginatedListView.DataSource
extension PaginatedListView {
	public struct DataSource: Sendable {
		let fetchNextItems: FetchNextItems
		let hasMoreItemsToLoad: HasMoreItemsToLoad
		let nextPageItemsCount: NextPageItemsCount

		public typealias FetchNextItems = @Sendable () async throws -> [Item]
		public typealias HasMoreItemsToLoad = @Sendable () -> Bool
		public typealias NextPageItemsCount = @Sendable () -> Int
	}
}

extension PaginatedListView.DataSource {
	static func fungibleResources() -> PaginatedListView.DataSource {
		.init {
			<#code#>
		} hasMoreItemsToLoad: {
			<#code#>
		} nextPageItemsCount: {
			<#code#>
		}
	}
}

// MARK: - PaginatedListView
struct PaginatedListView<Item: Identifiable & Hashable & Sendable, ItemView: SwiftUI.View>: FeatureReducer {
	let dataSource: DataSource

	public struct State: Hashable, Sendable {
		public let pageSize: Int
		public var loadedItems: IdentifiedArrayOf<Item>
		public var isLoadingResources: Bool = true
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case itemDidAppear(item: Item)
	}

	public enum InternalAction: Sendable, Equatable {
		case itemsLoaded(TaskResult<[Item]>)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			// load first items
			return loadResources(state)
		case let .itemDidAppear(item):
			guard state.loadedItems.last?.id == item.id else {
				return .none
			}
			return loadResources(state)
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .itemsLoaded(result):
			state.isLoadingResources = false
			switch result {
			case let .success(items):
				state.loadedItems.append(contentsOf: items)
				return .none
			case let .failure(error):
				return .none
			}
		}
	}

	func loadResources(_ state: State) -> Effect<Action> {
		guard !state.isLoadingResources, dataSource.hasMoreItemsToLoad() else {
			return .none
		}
		return .run { send in
			let result = await TaskResult { try await dataSource.fetchNextItems() }
			await send(.internal(.itemsLoaded(result)))
		}
	}
}

extension PaginatedListView {
	typealias View = AView<ItemView>

	@MainActor
	struct AView<ItemView: SwiftUI.View>: SwiftUI.View {
		private let store: StoreOf<PaginatedListView>
		private let itemBuilder: (Item) -> ItemView

		public init(store: StoreOf<PaginatedListView>, @ViewBuilder itemBuilder: @escaping (Item) -> ItemView) {
			self.store = store
			self.itemBuilder = itemBuilder
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				LazyVStack {
					ForEach(viewStore.loadedItems) { item in
						itemBuilder(item)
							.onAppear {
								viewStore.send(.itemDidAppear(item: item))
							}
					}
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}
	}
}
