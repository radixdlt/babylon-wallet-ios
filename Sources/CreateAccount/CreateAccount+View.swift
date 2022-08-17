import Common
import ComposableArchitecture
import SwiftUI

public extension CreateAccount {
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

public extension CreateAccount.View {
	var body: some View {
		// NOTE: placeholder implementation
		WithViewStore(store) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Create Account")
					Button(
						action: { viewStore.send(.coordinate(.dismissCreateAccount)) },
						label: { Text("Dismiss Create Account") }
					)
				}
			}
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
