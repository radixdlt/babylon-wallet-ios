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
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			LazyVStack(spacing: 25) {
				ForEachStore(
					store.scope(
						state: \.accounts,
						action: { .child(.account(id: $0, action: $1)) }
					),
					content: AccountList.Row.View.init(store:)
				)
			}
			.onAppear {
				viewStore.send(.viewAppeared)
			}
			.alert(store.scope(state: \.alert, action: { .view($0) }), dismiss: .alertDismissButtonTapped)
		}
	}
}

// MARK: - AccountList.View.ViewState
extension AccountList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountList.State) {}
	}
}

#if DEBUG

// MARK: - AccountList_Preview
struct AccountList_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.View(
			store: .init(
				initialState: .init(
					accounts: .placeholder,
					alert: nil
				),
				reducer: AccountList()
			)
		)
	}
}
#endif // DEBUG
