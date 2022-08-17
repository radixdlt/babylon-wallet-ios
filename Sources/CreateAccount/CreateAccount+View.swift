import ComposableArchitecture
import SwiftUI

public extension CreateAccount {
	struct View: SwiftUI.View {
		let store: Store<State, Action>
	}
}

public extension CreateAccount.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: CreateAccount.Action.init
			)
		) { _ in
			// TODO: implement
			Text("Impl: CreateAccount")
				.background(Color.yellow)
				.foregroundColor(.red)
		}
	}
}

extension CreateAccount.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension CreateAccount.Action {
	init(action: CreateAccount.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension CreateAccount.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: CreateAccount.State) {
			// TODO: implement
		}
	}
}
