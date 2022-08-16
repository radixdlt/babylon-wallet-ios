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
		WithViewStore(store) { store in
			ForceFullScreen {
				VStack {
					Text("Settings")
					Button(action: { store.send(.coordinate(.dismissSettings)) }, label: {
						Text("Dismiss Settings")
					})
				}
			}
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
