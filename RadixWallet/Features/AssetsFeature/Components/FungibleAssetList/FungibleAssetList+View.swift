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
			store.scope(state: \.sections) { .child(.section($0, $1)) }
		) {
			FungibleAssetList.Section.View(store: $0)
		}
		.destinations(with: store)
	}
}

private extension StoreOf<FungibleAssetList> {
	var destination: PresentationStoreOf<FungibleAssetList.Destination> {
		func scopeState(state: State) -> PresentationState<FungibleAssetList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FungibleAssetList>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
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
