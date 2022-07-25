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
		HStack(alignment: .top) {
			VStack(alignment: .leading, spacing: 10) {
				Text("Radar Wallet")
					.font(.title)
					.bold()
				Text("Welcome, here are all your\naccounts on the Radar Network")

				Spacer()
			}
			.background(Color.red)
			.padding()
			Spacer()
		}
	}
}

// MARK: - HomeView_Previews
#if DEBUG
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
#endif // DEBUG
