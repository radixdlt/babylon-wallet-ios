import ComposableArchitecture
import SwiftUI

struct NonFungibleAssetList: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var rows: IdentifiedArrayOf<NonFungibleAssetList.Row.State>
	}

	enum ChildAction: Sendable, Equatable {
		case asset(NonFungibleAssetList.Row.State.ID, NonFungibleAssetList.Row.Action)
	}

	enum InternalAction: Sendable, Equatable {
		case refreshRows([ResourceAddress])
	}

	enum DelegateAction: Sendable, Equatable {
		case selected(OnLedgerEntity.OwnedNonFungibleResource, token: OnLedgerEntity.NonFungibleToken)
	}

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.rows, action: /Action.child .. ChildAction.asset) {
				NonFungibleAssetList.Row()
			}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .asset(rowID, .delegate(.open(asset))):
			guard let row = state.rows[id: rowID] else {
				loggerGlobal.warning("Selected row does not exist \(rowID)")
				return .none
			}
			return .send(.delegate(.selected(row.resource, token: asset)))

		case .asset:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .refreshRows(rows):
			.merge(rows.map { .send(.child(.asset($0, .internal(.refreshResources)))) })
		}
	}
}
