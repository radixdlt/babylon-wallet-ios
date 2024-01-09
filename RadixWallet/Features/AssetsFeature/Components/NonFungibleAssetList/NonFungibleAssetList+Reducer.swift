import ComposableArchitecture
import SwiftUI
public struct NonFungibleAssetList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State>

		@PresentationState
		public var destination: Destination.State?

		public init(rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State>) {
			self.rows = rows
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case asset(NonFungibleAssetList.Row.State.ID, NonFungibleAssetList.Row.Action)
	}

	public struct Destination: DestinationReducer {
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

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.rows, action: /Action.child .. ChildAction.asset) {
				NonFungibleAssetList.Row()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .asset(rowID, .delegate(.open(asset))):
			guard let row = state.rows[id: rowID] else {
				loggerGlobal.warning("Selected row does not exist \(rowID)")
				return .none
			}

			state.destination = .details(.init(
				resourceAddress: row.id,
				ownedResource: row.resource,
				token: asset,
				ledgerState: row.resource.atLedgerState
			))
			return .none

		case .asset:
			return .none
		}
	}
}
