import ComposableArchitecture
import SwiftUI

// MARK: - FungibleAssetList.View
extension FungibleAssetList {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension FungibleAssetList.View {
	public var body: some View {
		ForEachStore(
			store.scope(
				state: \.sections,
				action: { childAction in
					.child(.section(childAction.0, childAction.1))
				}
			)
		) {
			FungibleAssetList.Section.View(store: $0)
		}
		.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /FungibleAssetList.Destination.State.details,
			action: FungibleAssetList.Destination.Action.details,
			content: { FungibleTokenDetails.View(store: $0) }
		)
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
