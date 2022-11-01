import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - AccountPreferences.View
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
			store,
			observe: ViewState.init(state:),
			send: AccountPreferences.Action.init
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Implement: AccountPreferences")
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

// MARK: - AccountPreferences.View.ViewAction
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

// MARK: - AccountPreferences.View.ViewState
extension AccountPreferences.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: AccountPreferences.State) {}
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
