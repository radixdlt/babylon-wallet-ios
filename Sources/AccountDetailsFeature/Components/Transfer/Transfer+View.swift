import Common
import ComposableArchitecture
import SwiftUI

public extension AccountDetails.Transfer {
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

public extension AccountDetails.Transfer.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountDetails.Transfer.Action.init
			)
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Impl: Transfer")
						.background(Color.yellow)
						.foregroundColor(.red)
					Button(
						action: { viewStore.send(.dismissTransferButtonTapped) },
						label: { Text("Dismiss Transfer") }
					)
				}
			}
		}
	}
}

extension AccountDetails.Transfer.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissTransferButtonTapped
	}
}

extension AccountDetails.Transfer.Action {
	init(action: AccountDetails.Transfer.View.ViewAction) {
		switch action {
		case .dismissTransferButtonTapped:
			self = .internal(.user(.dismissTransfer))
		}
	}
}

extension AccountDetails.Transfer.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.Transfer.State) {
			// TODO: implement
		}
	}
}

// MARK: - Transfer_Preview
struct Transfer_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.Transfer.View(
			store: .init(
				initialState: .init(),
				reducer: AccountDetails.Transfer.reducer,
				environment: .init()
			)
		)
	}
}
