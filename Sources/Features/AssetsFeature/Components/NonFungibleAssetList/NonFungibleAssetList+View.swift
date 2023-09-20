import FeaturePrelude

// MARK: - NonFungibleAssetList.View
extension NonFungibleAssetList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NonFungibleAssetList>

		public init(store: StoreOf<NonFungibleAssetList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			LazyVStack(spacing: .medium1) {
				ForEachStore(
					store.scope(state: \.rows) { .child(.asset($0, $1)) },
					content: {
						NonFungibleAssetList.Row.View(store: $0)
					}
				)
			}
			.task { @MainActor in
				await ViewStore(store, observe: { $0 }).send(.view(.task)).finish()
			}
			.overlay(alignment: .bottom) {
				WithViewStore(store.scope(state: \.isLoadingResources, action: actionless), observe: { $0 }) { viewStore in
					if viewStore.state {
						ProgressView()
					}
				}
			}
			.sheet(
				store: store.scope(state: \.$destination) { .child(.destination($0)) },
				state: /NonFungibleAssetList.Destinations.State.details,
				action: NonFungibleAssetList.Destinations.Action.details,
				content: { detailsStore in
					WithNavigationBar {
						store.send(.view(.closeDetailsTapped))
					} content: {
						NonFungibleTokenDetails.View(store: detailsStore)
					}
				}
			)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct NonFungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleAssetList.View(
			store: .init(
				initialState: .init(resources: []),
				reducer: NonFungibleAssetList.init
			)
		)
	}
}
#endif
