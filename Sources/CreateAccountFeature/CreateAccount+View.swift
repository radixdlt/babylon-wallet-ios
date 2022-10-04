import Common
import ComposableArchitecture
import SwiftUI

// MARK: - CreateAccount.View
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

// MARK: - CreateAccount.View.ViewAction
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

// MARK: - CreateAccount.View.ViewState
extension CreateAccount.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: CreateAccount.State) {
			// TODO: implement
		}
	}
}
