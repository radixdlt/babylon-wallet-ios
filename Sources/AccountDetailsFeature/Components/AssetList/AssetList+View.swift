import ComposableArchitecture
import SwiftUI

public extension AccountDetails.AssetList {
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

public extension AccountDetails.AssetList.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountDetails.AssetList.Action.init
			)
		) { _ in
			VStack(spacing: 30) {
				selectorView()

				LazyVStack(spacing: 20) {
					ForEachStore(
						store.scope(
							state: \.sections,
							action: AccountDetails.AssetList.Action.assetSection
						),
						content: AccountDetails.AssetSection.View.init(store:)
					)
				}
			}
		}
	}
}

// MARK: - Private Methods
private extension AccountDetails.AssetList.View {
	func selectorView() -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			Button(
				action: {
					// TODO: implement
				}, label: {
					Text(AccountDetails.AssetList.ListType.tokens.displayText)
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

extension AccountDetails.AssetList.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AccountDetails.AssetList.Action {
	init(action: AccountDetails.AssetList.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension AccountDetails.AssetList.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.AssetList.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetList_Preview
struct AssetList_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.AssetList.View(
			store: .init(
				initialState: .init(
					sections: []
				),
				reducer: AccountDetails.AssetList.reducer,
				environment: .init()
			)
		)
	}
}
