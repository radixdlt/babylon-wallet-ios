import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList.Section
extension FungibleAssetList {
	public struct Section: FeatureReducer {
		public struct State: Sendable, Hashable, Identifiable {
			public enum ID: Sendable, Hashable {
				case xrd
				case nonXrd
			}

			public let id: ID
			public var rows: IdentifiedArrayOf<Row.State>

			public init(
				id: ID,
				rows: IdentifiedArrayOf<Row.State> = []
			) {
				self.id = id
				self.rows = rows
			}
		}

		@CasePathable
		public enum ChildAction: Sendable, Equatable {
			case row(Row.State.ID, Row.Action)
		}

		public enum DelegateAction: Sendable, Equatable {
			case selected(OnLedgerEntity.OwnedFungibleResource)
		}

		public var body: some ReducerOf<Self> {
			Reduce(core)
				.forEach(\.rows, action: /Action.child .. ChildAction.row) {
					FungibleAssetList.Section.Row()
				}
		}

		public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleAssetList.Section>

		public init(store: StoreOf<FungibleAssetList.Section>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
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
