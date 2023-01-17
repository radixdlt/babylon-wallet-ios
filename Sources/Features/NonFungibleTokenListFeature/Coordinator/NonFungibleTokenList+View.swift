import FeaturePrelude

// MARK: - NonFungibleTokenList.View
public extension NonFungibleTokenList {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension NonFungibleTokenList.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(spacing: .medium1) {
				ForEachStore(
					store.scope(
						state: \.rows,
						action: { .child(.asset(id: $0, action: $1)) }
					),
					content: { NonFungibleTokenList.Row.View(store: $0) }
				)
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
						then: { NonFungibleTokenList.Detail.View(store: $0) }
					)
				}
			)
		}
	}
}

// MARK: - NonFungibleTokenList.View.ViewState
extension NonFungibleTokenList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var selectedToken: NonFungibleTokenList.Detail.State?

		init(state: NonFungibleTokenList.State) {
			self.selectedToken = state.selectedToken
		}
	}
}

// MARK: - NonFungibleTokenList_Preview
struct NonFungibleTokenList_Preview: PreviewProvider {
	static var previews: some View {
		NonFungibleTokenList.View(
			store: .init(
				initialState: .init(rows: []),
				reducer: NonFungibleTokenList()
			)
		)
	}
}
