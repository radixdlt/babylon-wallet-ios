import Common
import ComposableArchitecture
import SwiftUI

public extension Home.AccountDetails {
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

public extension Home.AccountDetails.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountDetails.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Account Details")
					Button(
						action: { viewStore.send(.dismissAccountDetailsButtonTapped) },
						label: { Text("Dismiss Account Details") }
					)
				}
			}
		}
	}
}

extension Home.AccountDetails.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountDetailsButtonTapped
	}
}

extension Home.AccountDetails.Action {
	init(action: Home.AccountDetails.View.ViewAction) {
		switch action {
		case .dismissAccountDetailsButtonTapped:
			self = .internal(.user(.dismissAccountDetails))
		}
	}
}

extension Home.AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AccountDetails.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountDetails_Preview
struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountDetails.View(
			store: .init(
				initialState: .init(state: .placeholder),
				reducer: Home.AccountDetails.reducer,
				environment: .init()
			)
		)
	}
}
