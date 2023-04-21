import FeaturePrelude

// MARK: - FungibleTokenList.View
extension FungibleTokenList {
	@MainActor
	public struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension FungibleTokenList.View {
	public var body: some View {
		VStack(spacing: .medium1) {
			IfLetStore(
				store.scope(
					state: \.xrdToken,
					action: { .child(.xrdRow($0)) }
				),
				then: { FungibleTokenList.Row.View(store: $0) }
			).background(
				RoundedRectangle(cornerRadius: .small1)
					.fill(Color.white)
					.tokenRowShadow()
			).padding(.horizontal, .medium3)

			LazyVStack(spacing: .medium2) {
				ForEachStore(
					store.scope(
						state: \.nonXrdTokens,
						action: { .child(.nonXRDRow($0, $1)) }
					),
					content: { FungibleTokenList.Row.View(store: $0) }
				)
			}.background(
				RoundedRectangle(cornerRadius: .small1)
					.fill(Color.white)
					.tokenRowShadow()
			).padding(.horizontal, .medium3)
		}
		.sheet(
			store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
			state: /FungibleTokenList.Destinations.State.details,
			action: FungibleTokenList.Destinations.Action.details,
			content: { FungibleTokenDetails.View(store: $0) }
		)
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct FungibleTokenList_Preview: PreviewProvider {
//	static var previews: some View {
//		FungibleTokenList.View(
//			store: .init(
//				initialState: .init(
//					sections: []
//				),
//				reducer: FungibleTokenList()
//			)
//		)
//	}
// }
// #endif
