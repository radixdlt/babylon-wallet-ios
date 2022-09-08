import Common
import ComposableArchitecture
import SwiftUI

public extension Home.CreateAccount {
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

public extension Home.CreateAccount.View {
	var body: some View {
		// NOTE: placeholder implementation
		WithViewStore(store) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Impl: Settings")
						.background(Color.yellow)
						.foregroundColor(.red)
					Button(
						action: { viewStore.send(.coordinate(.dismissCreateAccount)) },
						label: { Text("Dismiss Create Account") }
					)
				}
			}
		}
	}
}

extension Home.CreateAccount.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.CreateAccount.Action {
	init(action: Home.CreateAccount.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.CreateAccount.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.CreateAccount.State) {
			// TODO: implement
		}
	}
}
