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
	}

	public enum ChildAction: Sendable, Equatable {
		case asset(NonFungibleAssetList.Row.State.ID, NonFungibleAssetList.Row.Action)
		case destination(PresentationAction<Destinations.Action>)
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
		case .closeDetailsTapped:
			state.destination = nil
			return .none
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

		case .asset:
			return .none

		case .destination:
			return .none
		}
	}
}
