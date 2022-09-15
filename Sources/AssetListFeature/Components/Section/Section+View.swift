import ComposableArchitecture
import SwiftUI

public extension AssetList.Section {
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

public extension AssetList.Section.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AssetList.Section.Action.init
			)
		) { _ in
			LazyVStack(spacing: 0) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: AssetList.Section.Action.asset(id:action:)
					),
					content: AssetList.Row.View.init(store:)
				)
			}
			.background(
				RoundedRectangle(cornerRadius: 6)
					.fill(Color.white)
					.shadow(color: .app.shadowBlack, radius: 8, x: 0, y: 9)
			)
			.padding([.leading, .trailing], 18)
		}
	}
}

extension AssetList.Section.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AssetList.Section.Action {
	init(action: AssetList.Section.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension AssetList.Section.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AssetList.Section.State) {
			// TODO: implement
		}
	}
}

// MARK: - Section_Preview
struct Section_Preview: PreviewProvider {
	static var previews: some View {
		AssetList.Section.View(
			store: .init(
				initialState: .init(
					assets: []
				),
				reducer: AssetList.Section.reducer,
				environment: .init()
			)
		)
	}
}
