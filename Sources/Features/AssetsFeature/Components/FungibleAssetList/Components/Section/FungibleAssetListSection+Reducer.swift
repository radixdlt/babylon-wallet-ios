import FeaturePrelude

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

		public enum ChildAction: Sendable, Equatable {
			case row(Row.State.ID, Row.Action)
		}

		public enum DelegateAction: Sendable, Equatable {
			case selected(OnLedgerEntity.OwnedFungibleResource)
		}

		public var body: some ReducerOf<Self> {
			Reduce(core)
				.forEach(\.rows, action: /Action.child .. ChildAction.row, element: {
					FungibleAssetList.Section.Row()
				})
		}

		public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
			switch childAction {
			case let .row(_, .delegate(.selected(token))):
				return .send(.delegate(.selected(token)))
			case .row:
				return .none
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
						.rowStyle()
				}
			}
			.listSectionSeparator(.hidden)
		}
	}
}
