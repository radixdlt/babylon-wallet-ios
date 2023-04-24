import FeaturePrelude

// MARK: - NonFungibleTokenList.View
extension NonFungibleTokenList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleTokenList>

		public init(store: StoreOf<NonFungibleTokenList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			LazyVStack(spacing: .medium1) {
				ForEachStore(
					store.scope(
						state: \.rows,
						action: { .child(.asset($0, $1)) }
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
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.View(
			store: .init(
				initialState: .init(rows: []),
				reducer: NonFungibleTokenList()
			)
		)
	}
}
#endif
