import ComposableArchitecture
import SwiftUI

public extension Home.AssetSection {
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

public extension Home.AssetSection.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AssetSection.Action.init
			)
		) { _ in
			LazyVStack(spacing: 0) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: Home.AssetSection.Action.asset(id:action:)
					),
					content: Home.AssetRow.View.init(store:)
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

extension Home.AssetSection.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension Home.AssetSection.Action {
	init(action: Home.AssetSection.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension Home.AssetSection.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Home.AssetSection.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetSection_Preview
struct AssetSection_Preview: PreviewProvider {
	static var previews: some View {
		Home.AssetSection.View(
			store: .init(
				initialState: .init(
					assets: []
				),
				reducer: Home.AssetSection.reducer,
				environment: .init()
			)
		)
	}
}
