import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList.Section
extension FungibleAssetList {
	struct Section: FeatureReducer {
		struct State: Sendable, Hashable, Identifiable {
			enum ID: Sendable, Hashable {
				case xrd
				case nonXrd
			}

			let id: ID
			var rows: IdentifiedArrayOf<Row.State>

			init(
				id: ID,
				rows: IdentifiedArrayOf<Row.State> = []
			) {
				self.id = id
				self.rows = rows
			}
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case row(Row.State.ID, Row.Action)
		}

		enum DelegateAction: Sendable, Equatable {
			case selected(OnLedgerEntity.OwnedFungibleResource)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
				.forEach(\.rows, action: /Action.child .. ChildAction.row) {
					FungibleAssetList.Section.Row()
				}
		}

		func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .row(_, .delegate(.selected(resource))):
				.send(.delegate(.selected(resource)))
			case .row:
				.none
			}
		}
	}
}

// MARK: - FungibleAssetList.Section.View
extension FungibleAssetList.Section {
	struct View: SwiftUI.View {
		private let store: StoreOf<FungibleAssetList.Section>

		init(store: StoreOf<FungibleAssetList.Section>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			Section {
				ForEachStore(
					store.scope(
						state: \.rows,
						action: { .child(.row($0, $1)) }
					)
				) { rowStore in
					FungibleAssetList.Section.Row.View(store: rowStore)
						.rowStyle(showSeparator: true)
				}
			}
			.listSectionSeparator(.hidden)
		}
	}
}
