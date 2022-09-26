import ComposableArchitecture
import FungibleTokenListFeature
import SwiftUI

// MARK: - AssetsView.View
public extension AssetsView {
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

public extension AssetsView.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AssetsView.Action.init
			)
		) { viewStore in
			VStack(spacing: 30) {
				selectorView()

				switch viewStore.state.type {
				case .tokens:
					FungibleTokenList.View(
						store: store.scope(
							state: \.fungibleTokenList,
							action: AssetsView.Action.fungibleTokenList
						)
					)
				case .nfts:
					Text("NFTs")
				case .poolShare:
					Text("Pool Share")
				case .badges:
					Text("Badges")
				}
			}
		}
	}
}

// MARK: - Private Methods
private extension AssetsView.View {
	func selectorView() -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			Button(
				action: {
					// TODO: implement
				}, label: {
					Text(AssetsView.AssetsViewType.tokens.displayText)
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

// MARK: - AssetsView.View.ViewAction
extension AssetsView.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AssetsView.Action {
	init(action: AssetsView.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

// MARK: - AssetsView.View.ViewState
extension AssetsView.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var type: AssetsView.AssetsViewType

		init(state: AssetsView.State) {
			type = state.type
		}
	}
}

// MARK: - AssetList_Preview
struct AssetList_Preview: PreviewProvider {
	static var previews: some View {
		AssetsView.View(
			store: .init(
				initialState: .init(
					fungibleTokenList: .init(sections: [])
				),
				reducer: AssetsView.reducer,
				environment: .init()
			)
		)
	}
}
