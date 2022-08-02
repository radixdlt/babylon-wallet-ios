import Common
import ComposableArchitecture
import SwiftUI

public extension Home {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Home.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
        /*
		var hasNotification: Bool
		init(state: Home.State) {
			hasNotification = state.hasNotification
		}
        */
	}
}

internal extension Home.Coordinator {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case settingsButtonTapped
	}
}

internal extension Home.Action {
	init(action: Home.Coordinator.ViewAction) {
        /*
		switch action {
		case .settingsButtonTapped:
			self = .internal(.user(.settingsButtonTapped))
		}
        */
        fatalError()
	}
}

public extension Home.Coordinator {
	// MARK: Body
	var body: some View {
		VStack {
			/*
			 Home.Header.View(
			     store: store.scope(
			         state: \.Home.Header.State.init
			         action: \Home.Header.Action))
			 */
		}
	}
}

// MARK: - HomeView_Previews
#if DEBUG
/*
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Home.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Home.reducer,
				environment: .init()
			)
		)
	}
}
*/
#endif // DEBUG
