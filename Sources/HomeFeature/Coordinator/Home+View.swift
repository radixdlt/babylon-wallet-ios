import ComposableArchitecture
import SwiftUI

public extension Home {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Home.Coordinator {
	// MARK: Body
	var body: some View {
		VStack {
			Home.Header.View(
				store: store.scope(
					state: \.header,
					action: Home.Action.header
				)
			)
			Spacer()
			Home.Balance.View(
				store: store.scope(
					state: \.balance,
					action: Home.Action.balance
				)
			)
			Spacer()
			Home.VisitHub.View(
				store: store.scope(
					state: \.visitHub,
					action: Home.Action.visitHub
				)
			)
		}
		.padding(32)
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
