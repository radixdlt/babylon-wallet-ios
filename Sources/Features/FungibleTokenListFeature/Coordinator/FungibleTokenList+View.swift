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
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ZStack {
				VStack(spacing: .large2) {
					LazyVStack(spacing: .medium2) {
						ForEachStore(
							store.scope(
								state: \.sections,
								action: { .child(.section(id: $0, action: $1)) }
							),
							content: { FungibleTokenList.Section.View(store: $0) }
						)
					}
				}
			}
			.sheet(
				unwrapping: viewStore.binding(
					get: \.selectedToken,
					send: { .selectedTokenChanged($0) }
				),
				content: { _ in
					IfLetStore(
						store.scope(
							state: \.selectedToken,
							action: { .child(.details($0)) }
						),
						then: { FungibleTokenDetails.View(store: $0) }
					)
				}
			)
		}
	}
}

// MARK: - FungibleTokenList.View.ViewState
extension FungibleTokenList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var selectedToken: FungibleTokenContainer?

		init(state: FungibleTokenList.State) {
			self.selectedToken = state.selectedToken
		}
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
