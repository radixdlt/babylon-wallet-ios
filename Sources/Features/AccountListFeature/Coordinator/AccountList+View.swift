import FeaturePrelude

// MARK: - AccountList.View
extension AccountList {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

extension AccountList.View {
	public var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			LazyVStack(spacing: .medium1) {
				ForEachStore(
					store.scope(
						state: \.accounts,
						action: { .child(.account(id: $0, action: $1)) }
					),
					content: { AccountList.Row.View(store: $0) }
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
import SwiftUI // NB: necessary for previews to appear

struct AccountList_Preview: PreviewProvider {
	static var previews: some View {
		AccountList.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountList()
			)
		)
	}
}
#endif
