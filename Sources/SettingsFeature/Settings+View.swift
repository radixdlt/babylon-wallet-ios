import Common
import ComposableArchitecture
import SwiftUI

public extension Settings {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Settings.Coordinator {
	// MARK: Body
	var body: some View {
		// NOTE: placeholder implementation
		ForceFullScreen {
			Text("Settings")
		}
	}
}

// MARK: - HomeView_Previews
#if DEBUG
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Settings.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Settings.reducer,
				environment: .init()
			)
		)
	}
}
#endif // DEBUG
