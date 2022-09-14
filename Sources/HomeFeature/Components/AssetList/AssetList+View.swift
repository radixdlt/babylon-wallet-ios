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
			VStack(spacing: 30) {
				selectorView()

				LazyVStack(spacing: 25) {
					ForEachStore(
						store.scope(
							state: \.sections,
							action: Home.AssetList.Action.assetSection
						),
						content: Home.AssetSection.View.init(store:)
					)
				}
			}
		}
	}
}

// MARK: - Private Methods
private extension Home.AssetList.View {
	func selectorView() -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			Button(
				action: {
					// TODO: implement
				}, label: {
					Text(Home.AssetList.ListType.tokens.displayText)
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
					sections: []
				),
				reducer: Home.AssetList.reducer,
				environment: .init()
			)
		)
	}
}
