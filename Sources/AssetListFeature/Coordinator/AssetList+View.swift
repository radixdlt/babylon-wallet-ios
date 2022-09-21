import ComposableArchitecture
import SwiftUI

public extension AssetList {
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

public extension AssetList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AssetList.Action.init
			)
		) { _ in
			VStack(spacing: 30) {
				selectorView()

				LazyVStack(spacing: 20) {
					ForEachStore(
						store.scope(
							state: \.sections,
							action: AssetList.Action.section
						),
						content: AssetList.Section.View.init(store:)
					)
				}
			}
		}
	}
}

// MARK: - Private Methods
private extension AssetList.View {
	func selectorView() -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			Button(
				action: {
					// TODO: implement
				}, label: {
					Text(AssetList.ListType.tokens.displayText)
						.foregroundColor(.app.buttonTextWhite)
						.font(.app.buttonBody)
						.frame(height: 40)
						.padding([.leading, .trailing], 16)
						.background(RoundedRectangle(cornerRadius: 21)
							.fill(Color.app.buttonBackgroundDark2)
						)
						.padding([.leading, .trailing], 18)
				}
			)
		}
	}
}

extension AssetList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AssetList.Action {
	init(action: AssetList.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension AssetList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AssetList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetList_Preview
struct AssetList_Preview: PreviewProvider {
	static var previews: some View {
		AssetList.View(
			store: .init(
				initialState: .init(
					sections: []
				),
				reducer: AssetList.reducer,
				environment: .init()
			)
		)
	}
}
