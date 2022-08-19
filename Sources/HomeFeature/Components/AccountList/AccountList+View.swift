import ComposableArchitecture
import SwiftUI

public extension Home.AccountList {
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

public extension Home.AccountList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountList.Action.init
			)
		) { _ in
			LazyVStack(spacing: 25) {
				ForEachStore(
					store.scope(
						state: \.accounts,
						action: Home.AccountList.Action.account(id:action:)
					),
					content: Home.AccountRow.View.init(store:)
				)
			}
			.onAppear {
//				viewStore.send(.viewDidAppear)
			}
			.alert(store.scope(state: \.alert), dismiss: .internal(.user(.alertDismissed)))
		}
	}
}

extension Home.AccountList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case viewDidAppear
	}
}

extension Home.AccountList.Action {
	init(action: Home.AccountList.View.ViewAction) {
		switch action {
		case .viewDidAppear:
			self = .internal(.system(.viewDidAppear))
		}
	}
}

extension Home.AccountList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AccountList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountList_Preview
struct AccountList_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountList.View(
			store: .init(
				initialState: .init(accounts: .placeholder, alert: nil),
				reducer: Home.AccountList.reducer,
				environment: .init(wallet: .placeholder)
			)
		)
	}
}
