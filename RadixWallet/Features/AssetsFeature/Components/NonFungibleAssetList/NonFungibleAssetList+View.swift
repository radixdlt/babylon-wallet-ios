import ComposableArchitecture
import SwiftUI

// MARK: - NonFungibleAssetList.View
extension NonFungibleAssetList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleAssetList>

		public init(store: StoreOf<NonFungibleAssetList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ForEachStore(
				store.scope(state: \.rows) { .child(.asset($0, $1)) },
				content: {
					NonFungibleAssetList.Row.View(store: $0)
				}
			)
			.destinations(with: store)
		}
	}
}

private extension StoreOf<NonFungibleAssetList> {
	var destination: PresentationStoreOf<NonFungibleAssetList.Destination> {
		func scopeState(state: State) -> PresentationState<NonFungibleAssetList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<NonFungibleAssetList>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /NonFungibleAssetList.Destination.State.details,
			action: NonFungibleAssetList.Destination.Action.details,
			content: { NonFungibleTokenDetails.View(store: $0) }
		)
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
