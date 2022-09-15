import Common
import ComposableArchitecture
import SwiftUI

public extension AccountPreferences {
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

public extension AccountPreferences.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountPreferences.Action.init
			)
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Impl: AccountPreferences")
						.background(Color.yellow)
						.foregroundColor(.red)
					Button(
						action: { viewStore.send(.dismissAccountPreferencesButtonTapped) },
						label: { Text("Dismiss AccountPreferences") }
					)
				}
			}
		}
	}
}

extension AccountPreferences.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountPreferencesButtonTapped
	}
}

extension AccountPreferences.Action {
	init(action: AccountPreferences.View.ViewAction) {
		switch action {
		case .dismissAccountPreferencesButtonTapped:
			self = .internal(.user(.dismissAccountPreferences))
		}
	}
}

extension AccountPreferences.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountPreferences.State) {
			// TODO: implement
		}
	}
}

// MARK: - AccountPreferences_Preview
struct AccountPreferences_Preview: PreviewProvider {
	static var previews: some View {
		AccountPreferences.View(
			store: .init(
				initialState: .init(),
				reducer: AccountPreferences.reducer,
				environment: .init()
			)
		)
	}
}
