import Common
import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails.Transfer.View
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
			store,
			observe: ViewState.init(state:),
			send: AccountDetails.Transfer.Action.init
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Implement: Transfer")
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

// MARK: - AccountDetails.Transfer.View.ViewAction
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

// MARK: - AccountDetails.Transfer.View.ViewState
extension AccountDetails.Transfer.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.Transfer.State) {}
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
