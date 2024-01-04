extension StakeUnitList.State {
	var viewState: StakeUnitList.ViewState {
		.init()
	}
}

// MARK: - StakeUnitList.View

public extension StakeUnitList {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<StakeUnitList>

		public init(store: StoreOf<StakeUnitList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			componentsView
				.onAppear {
					store.send(.view(.appeared))
				}
		}

		private var componentsView: some SwiftUI.View {
			ForEachStore(
				store.scope(
					state: \.stakes,
					action: (
						/StakeUnitList.Action.child
							.. StakeUnitList.ChildAction.stake
					).embed
				),
				content: LSUStake.View.init
			)
		}
	}
}
