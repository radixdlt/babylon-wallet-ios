import FeaturePrelude

// MARK: - NonFungibleTokenList.View
extension NonFungibleTokenList {
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

extension NonFungibleTokenList.View {
	public var body: some View {
		LazyVStack(spacing: .medium1) {
			ForEachStore(
				store.scope(
					state: \.rows,
					action: { .child(.asset(id: $0, action: $1)) }
				),
				content: { NonFungibleTokenList.Row.View(store: $0) }
			)
		}
		.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /NonFungibleTokenList.Destinations.State.details,
			action: NonFungibleTokenList.Destinations.Action.details,
			content: { NonFungibleTokenList.Detail.View(store: $0) }
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.View(
			store: .init(
				initialState: .init(rows: [.init(container: .mock1)]),
				reducer: NonFungibleTokenList()
			)
		)
	}
}
#endif
