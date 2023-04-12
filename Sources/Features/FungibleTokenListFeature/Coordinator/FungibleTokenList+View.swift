import FeaturePrelude
import FungibleTokenDetailsFeature

// MARK: - FungibleTokenList.View
extension FungibleTokenList {
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

extension FungibleTokenList.View {
	public var body: some View {
		LazyVStack(spacing: .medium2) {
                        IfLetStore(
                                store.scope(state: \.xrdToken, action: { .child(.row($0))}),
                                then: { FungibleTokenList.Row.View(store: $0) })

			ForEachStore(
				store.scope(
                                        state: \.nonXrdTokens,
                                        action: { .child(.row($0)) }
				),
				content: { FungibleTokenList.Row.View(store: $0) }
			)

                        ProgressView().onAppear {
                                ViewStore(store).send(.view(.scrolledToLoadMore))
                        }
		}
		.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /FungibleTokenList.Destinations.State.details,
			action: FungibleTokenList.Destinations.Action.details,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct FungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.View(
			store: .init(
				initialState: .init(
					sections: []
				),
				reducer: FungibleTokenList()
			)
		)
	}
}
#endif
