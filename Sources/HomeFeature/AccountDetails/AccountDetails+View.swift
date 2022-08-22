import Common
import ComposableArchitecture
import SwiftUI

public extension AccountDetails {
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

public extension AccountDetails.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountDetails.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Settings")
					Button(
						action: { viewStore.send(.dismissAccountDetailsButtonTapped) },
						label: { Text("Dismiss Account Details") }
					)
				}
			}
		}
	}
}

extension AccountDetails.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountDetailsButtonTapped
	}
}

extension AccountDetails.Action {
	init(action: AccountDetails.View.ViewAction) {
		switch action {
		case .dismissAccountDetailsButtonTapped:
			self = .internal(.user(.dismissAccountDetails))
		}
	}
}

extension AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountDetails_Preview
struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.View(
			store: .init(
				initialState: .init(state: .placeholder),
				reducer: AccountDetails.reducer,
				environment: .init()
			)
		)
	}
}
