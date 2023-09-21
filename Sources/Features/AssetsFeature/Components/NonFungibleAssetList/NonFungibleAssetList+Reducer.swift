import FeaturePrelude
import OnLedgerEntitiesClient

public struct NonFungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State> = []

		public let resources: AccountPortfolio.NonFungibleResources

		@PresentationState
		public var destination: Destinations.State?
		public var loadedPages: Int = 0
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
					state.loadedPages += 1
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

		let pageIndex = state.loadedPages + 1

		let addresses = resourcess.map(\.resource.resourceAddress)
		state.isLoadingResources = true
		return .run { send in
			let result = await TaskResult { try await onLedgerEntitiesClient.getResources(addresses) }
			await send(.internal(.resourceDetailsLoaded(result)))
		}
	}
}
