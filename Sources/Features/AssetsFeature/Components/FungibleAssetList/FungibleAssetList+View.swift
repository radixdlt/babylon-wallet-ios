import FeaturePrelude

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
		VStack(spacing: .medium1) {
			IfLetStore(
				store.scope(
					state: \.xrdToken,
					action: { .child(.xrdRow($0)) }
				),
				then: { store in
					Card {
						FungibleAssetList.Row.View(store: store)
					}
				}
			)
			.padding(.horizontal, .medium3)

			Card {
				LazyVStack(spacing: 0) {
					ForEachStore(
						store.scope(
							state: \.nonXrdTokens,
							action: { .child(.nonXRDRow($0, $1)) }
						)
					) { rowStore in
						FungibleAssetList.Row.View(store: rowStore)
							.separator(.bottom)
					}
				}
			}
			.padding(.horizontal, .medium3)
		}
		.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /FungibleAssetList.Destinations.State.details,
			action: FungibleAssetList.Destinations.Action.details,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct FungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		FungibleAssetList.View(
			store: .init(
				initialState: .init(),
				reducer: FungibleAssetList()
			)
		)
	}
}
#endif
