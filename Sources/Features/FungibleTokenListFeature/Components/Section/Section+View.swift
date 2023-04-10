import FeaturePrelude

// MARK: - FungibleTokenList.Section.View
extension FungibleTokenList.Section {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleTokenList.Section>

		public init(store: StoreOf<FungibleTokenList.Section>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
                        WithViewStore(store, observe: { $0 }) { viewStore in
                                LazyVStack(spacing: .zero) {
                                        ForEachStore(
                                                store.scope(
                                                        state: \.assets,
                                                        action: { .child(.asset(id: $0, action: $1)) }
                                                ),
                                                content: { FungibleTokenList.Row.View(store: $0) }
                                        )
                                }
                                .background(
                                        RoundedRectangle(cornerRadius: .small1)
                                                .fill(Color.white)
                                                .tokenRowShadow()
                                )
                                .padding(.horizontal, .medium3)
                        }
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct Section_Preview: PreviewProvider {
	static var previews: some View {
		FungibleTokenList.Section.View(
			store: .init(
				initialState: .init(
                                        id: .nonXrd, assets: []
				),
				reducer: FungibleTokenList.Section()
			)
		)
	}
}
#endif
