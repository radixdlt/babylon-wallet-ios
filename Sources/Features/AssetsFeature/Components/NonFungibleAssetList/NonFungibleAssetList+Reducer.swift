import FeaturePrelude

public struct NonFungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State>

		@PresentationState
		public var destination: Destinations.State?

		public init(rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State>) {
			self.rows = rows
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeDetailsTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case asset(NonFungibleAssetList.Row.State.ID, NonFungibleAssetList.Row.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case details(NonFungibleTokenDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case details(NonFungibleTokenDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.details, action: /Action.details) {
				NonFungibleTokenDetails()
			}
		}
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.rows, action: /Action.child .. ChildAction.asset) {
				NonFungibleAssetList.Row()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeDetailsTapped:
			state.destination = nil
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .asset(rowID, .delegate(.open(localID))):
			guard let row = state.rows[id: rowID] else {
				loggerGlobal.warning("Selected row does not exist \(rowID)")
				return .none
			}
			guard let token = row.resource.tokens[id: localID] else {
				loggerGlobal.warning("Selected token does not exist: \(localID)")
				return .none
			}

			state.destination = .details(.init(token: token, resource: row.resource))
			return .none

		case .asset:
			return .none

		case .destination:
			return .none
		}
	}
}
