import ComposableArchitecture
import SwiftUI

public extension AccountDetails.AssetSection {
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

public extension AccountDetails.AssetSection.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountDetails.AssetSection.Action.init
			)
		) { _ in
			LazyVStack(spacing: 0) {
				ForEachStore(
					store.scope(
						state: \.assets,
						action: AccountDetails.AssetSection.Action.asset(id:action:)
					),
					content: AccountDetails.AssetRow.View.init(store:)
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

extension AccountDetails.AssetSection.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {}
}

extension AccountDetails.AssetSection.Action {
	init(action: AccountDetails.AssetSection.View.ViewAction) {
		switch action {
		default:
			// TODO: implement
			break
		}
	}
}

extension AccountDetails.AssetSection.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountDetails.AssetSection.State) {
			// TODO: implement
		}
	}
}

// MARK: - AssetSection_Preview
struct AssetSection_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.AssetSection.View(
			store: .init(
				initialState: .init(
					assets: []
				),
				reducer: AccountDetails.AssetSection.reducer,
				environment: .init()
			)
		)
	}
}
