import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList.View
extension FungibleAssetList {
	@MainActor
	struct View: SwiftUI.View {
		typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		init(store: Store) {
			self.store = store
		}
	}
}

extension FungibleAssetList.View {
	var body: some View {
		ForEachStore(
			store.scope(state: \.sections) { .child(.section($0, $1)) }
		) {
			FungibleAssetList.Section.View(store: $0)
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct FungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		FungibleAssetList.View(
			store: .init(
				initialState: .init(),
				reducer: FungibleAssetList.init
			)
		)
	}
}
#endif
