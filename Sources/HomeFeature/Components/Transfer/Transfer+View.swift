import Common
import ComposableArchitecture
import SwiftUI

public extension Home.Transfer {
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

public extension Home.Transfer.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.Transfer.Action.init
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

extension Home.Transfer.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissTransferButtonTapped
	}
}

extension Home.Transfer.Action {
	init(action: Home.Transfer.View.ViewAction) {
		switch action {
		case .dismissTransferButtonTapped:
			self = .internal(.user(.dismissTransfer))
		}
	}
}

extension Home.Transfer.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.Transfer.State) {
			// TODO: implement
		}
	}
}

// MARK: - Transfer_Preview
struct Transfer_Preview: PreviewProvider {
	static var previews: some View {
		Home.Transfer.View(
			store: .init(
				initialState: .init(),
				reducer: Home.Transfer.reducer,
				environment: .init()
			)
		)
	}
}
