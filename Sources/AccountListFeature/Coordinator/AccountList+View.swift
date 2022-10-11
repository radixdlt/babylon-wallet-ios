import ComposableArchitecture
import SwiftUI

// MARK: - AccountList.View
public extension AccountList {
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

public extension AccountList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountList.Action.init
			)
		) { viewStore in
			LazyVStack(spacing: 25) {
				ForEachStore(
					store.scope(
						state: \.accounts,
						action: AccountList.Action.account(id:action:)
					),
					content: AccountList.Row.View.init(store:)
				)
			}
			.onAppear {
				viewStore.send(.didAppear)
			}
			.alert(store.scope(state: \.alert), dismiss: .internal(.user(.alertDismissed)))
		}
	}
}

// MARK: - AccountList.View.ViewAction
extension AccountList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case didAppear
	}
}

extension AccountList.Action {
	init(action: AccountList.View.ViewAction) {
		switch action {
		case .didAppear:
			self = .internal(.user(.loadAccounts))
		}
	}
}

// MARK: - AccountList.View.ViewState
extension AccountList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountList_Preview
struct AccountList_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.View(
			store: .init(
				initialState: .init(
					accounts: .placeholder,
					alert: nil
				),
				reducer: AccountList.reducer,
				environment: .init()
			)
		)
	}
}
