import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenList.Section.View
public extension FungibleTokenList.Section {
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

public extension FungibleTokenList.Section.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: FungibleTokenList.Section.Action.init
			)
		) { _ in
			LazyVStack(spacing: 0) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: FungibleTokenList.Section.Action.asset(id:action:)
					),
					content: FungibleTokenList.Row.View.init(store:)
				)
			}
			.background(
				RoundedRectangle(cornerRadius: 6)
					.fill(Color.white)
					.shadow(color: .app.shadowBlack, radius: 8, x: 0, y: 9)
			)
			.padding([.leading, .trailing], 18)
		}
	}
}

// MARK: - FungibleTokenList.Section.View.ViewAction
extension FungibleTokenList.Section.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension FungibleTokenList.Section.Action {
	init(action: FungibleTokenList.Section.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - FungibleTokenList.Section.View.ViewState
extension FungibleTokenList.Section.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: FungibleTokenList.Section.State) {
			// TODO: implement
		}
	}
}

// MARK: - Section_Preview
struct Section_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.Section.View(
			store: .init(
				initialState: .init(
					id: .nonXrd, assets: []
				),
				reducer: FungibleTokenList.Section.reducer,
				environment: .init()
			)
		)
	}
}
