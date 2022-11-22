import ComposableArchitecture
import SwiftUI

// MARK: - FungibleTokenList.Section.View
public extension FungibleTokenList.Section {
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

public extension FungibleTokenList.Section.View {
	var body: some View {
		WithViewStore(
			store.actionless,
			observe: ViewState.init(state:)
		) { _ in
			LazyVStack(spacing: .zero) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: { .child(.asset(id: $0, action: $1)) }
					),
					content: FungibleTokenList.Row.View.init(store:)
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

// MARK: - FungibleTokenList.Section.View.ViewState
extension FungibleTokenList.Section.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: FungibleTokenList.Section.State) {}
	}
}

// MARK: - Section_Preview
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
