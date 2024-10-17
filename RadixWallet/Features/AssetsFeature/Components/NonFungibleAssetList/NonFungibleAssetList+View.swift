import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleAssetList.View
extension NonFungibleAssetList {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleAssetList>

		init(store: StoreOf<NonFungibleAssetList>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			ForEachStore(
				store.scope(state: \.rows) { .child(.asset($0, $1)) },
				content: {
					NonFungibleAssetList.Row.View(store: $0)
				}
			)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct NonFungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleAssetList.View(
			store: .init(
				initialState: .init(rows: []),
				reducer: NonFungibleAssetList.init
			)
		)
	}
}
#endif
