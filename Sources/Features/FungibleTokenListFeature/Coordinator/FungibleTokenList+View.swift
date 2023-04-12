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
                        IfLetStore(store.scope(state: \.xrdToken)) { <#Store<State, Action>#> in
                                FungibleTokenList.Row.View(store: <#T##StoreOf<FungibleTokenList.Row>#>)
                        }
                        store.scope(state: \.xrdToken)

			ForEachStore(
				store.scope(
					state: \.sections,
					action: { .child(.section(id: $0, action: $1)) }
				),
				content: { FungibleTokenList.Section.View(store: $0) }
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
