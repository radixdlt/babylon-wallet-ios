import Common
import ComposableArchitecture
import SwiftUI

public extension Settings {
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

public extension Settings.View {
	var body: some View {
		// NOTE: placeholder implementation
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Settings.Action.init
			)
		) { viewStore in
			// TODO: implement
			ForceFullScreen {
				VStack {
					Text("Impl: Settings")
						.background(Color.yellow)
						.foregroundColor(.red)
					Button(
						action: { viewStore.send(.dismissSettingsButtonTapped) },
						label: { Text("Dismiss Settings") }
					)
				}
			}
		}
	}
}

public extension Settings.View {
	struct ViewState: Equatable {
		public init(_: Settings.State) {}
	}
}

public extension Settings.View {
	enum ViewAction: Equatable {
		case dismissSettingsButtonTapped
	}
}

extension Settings.Action {
	init(action: Settings.View.ViewAction) {
		switch action {
		case .dismissSettingsButtonTapped:
			self = .internal(.user(.dismissSettings))
		}
	}
}

// MARK: - HomeView_Previews
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Settings.View(
			store: .init(
				initialState: .init(),
				reducer: Settings.reducer,
				environment: .init()
			)
		)
	}
}
