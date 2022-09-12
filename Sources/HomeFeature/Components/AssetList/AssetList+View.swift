import ComposableArchitecture
import SwiftUI

public extension Home.AssetList {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Home.AssetList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AssetList.Action.init
			)
		) { _ in
			// TODO: implement
			Text("Impl: AssetList")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

extension Home.AssetList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AssetList.Action {
	init(action: Home.AssetList.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AssetList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AssetList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetList_Preview
struct AssetList_Preview: PreviewProvider {
	static var previews: some View {
		Home.AssetList.View(
			store: .init(
				initialState: .init(),
				reducer: Home.AssetList.reducer,
				environment: .init()
			)
		)
	}
}
