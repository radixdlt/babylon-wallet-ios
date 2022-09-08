import Common
import ComposableArchitecture
import SwiftUI

public extension Splash {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Splash.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Splash.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Splash")
				}
			}
			.onAppear {
				viewStore.send(.viewDidAppear)
			}
		}
	}
}

extension Splash.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Splash.State) {}
	}
}

extension Splash.View {
	// MARK: ViewAction
	enum ViewAction {
		case viewDidAppear
	}
}

extension Splash.Action {
	init(action: Splash.View.ViewAction) {
		switch action {
		case .viewDidAppear:
			self = .internal(.system(.viewDidAppear))
		}
	}
}

// MARK: - SplashView_Previews
struct SplashView_Previews: PreviewProvider {
	static var previews: some View {
		Splash.View(
			store: .init(
				initialState: .init(),
				reducer: Splash.reducer,
				environment: .init(
					backgroundQueue: .immediate,
					mainQueue: .immediate,
					profileLoader: .noop,
					walletLoader: .noop
				)
			)
		)
	}
}
