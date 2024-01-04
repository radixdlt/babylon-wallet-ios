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
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: StakeUnitList")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - StakeUnitList_Preview

struct StakeUnitList_Preview: PreviewProvider {
	static var previews: some View {
		StakeUnitList.View(
			store: .init(
				initialState: .previewValue,
				reducer: StakeUnitList.init
			)
		)
	}
}

public extension StakeUnitList.State {
	static let previewValue = Self()
}
#endif
