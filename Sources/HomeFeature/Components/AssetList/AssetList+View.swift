import ComposableArchitecture
import SwiftUI

public extension Home.AssetList {
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

public extension Home.AssetList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AssetList.Action.init
			)
		) { _ in
			LazyVStack(spacing: 25) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: Home.AssetList.Action.asset(id:action:)
					),
					content: { store in
						VStack {
							Home.AssetRow.View(store: store)
                            // TODO: exclude if last row
							separator()
						}
					}
				)
			}
			.background(Color.white
//				.shadow(color: .black.opacity(0.5), radius: 5, x: 5, y: 5)
			)
			.cornerRadius(6)
		}
	}

	func separator() -> some View {
		Rectangle()
			.padding([.leading, .trailing], 18)
			.foregroundColor(.app.separatorLightGray)
			.frame(height: 1)
	}
}

extension Home.AssetList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AssetList.Action {
	init(action: Home.AssetList.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AssetList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AssetList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetList_Preview
struct AssetList_Preview: PreviewProvider {
	static var previews: some View {
		Home.AssetList.View(
			store: .init(
				initialState: .init(
					assets: []
				),
				reducer: Home.AssetList.reducer,
				environment: .init()
			)
		)
	}
}
