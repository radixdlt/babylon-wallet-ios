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

public extension Home.Coordinator {
	// MARK: Body
	var body: some View {
//		VStack {
//			/*
//			 Home.Header.View(
//			     store: store.scope(
//			         state: \.Home.Header.State.init
//			         action: \Home.Header.Action))
//			 */
//		}
		Text("NO VIEW")
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
