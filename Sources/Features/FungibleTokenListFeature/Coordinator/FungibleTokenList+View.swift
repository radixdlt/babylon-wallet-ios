import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenList.View
public extension FungibleTokenList {
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

public extension FungibleTokenList.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: FungibleTokenList.Action.init
		) { _ in
			VStack(spacing: 30) {
				LazyVStack(spacing: 20) {
					ForEachStore(
						store.scope(
							state: \.sections,
							action: { .child(.section(id: $0, action: $1)) }
						),
						content: FungibleTokenList.Section.View.init(store:)
					)
				}
			}
		}
	}
}

// MARK: - FungibleTokenList.View.ViewAction
extension FungibleTokenList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension FungibleTokenList.Action {
	init(action: FungibleTokenList.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - FungibleTokenList.View.ViewState
extension FungibleTokenList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: FungibleTokenList.State) {}
	}
}

// MARK: - FungibleTokenList_Preview
struct FungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.View(
			store: .init(
				initialState: .init(
					sections: []
				),
				reducer: FungibleTokenList()
			)
		)
	}
}
