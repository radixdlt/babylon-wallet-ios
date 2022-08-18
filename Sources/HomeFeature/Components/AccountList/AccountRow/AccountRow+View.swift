import ComposableArchitecture
import SwiftUI

public extension Home.AccountRow {
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

public extension Home.AccountRow.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountRow.Action.init
			)
		) { _ in
			// TODO: implement
			Text("Impl: AccountRow")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

extension Home.AccountRow.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AccountRow.Action {
	init(action: Home.AccountRow.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AccountRow.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AccountRow.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountRow_Preview
struct AccountRow_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountRow.View(
			store: .init(
				initialState: .placeholder,
				reducer: Home.AccountRow.reducer,
				environment: .init()
			)
		)
	}
}
