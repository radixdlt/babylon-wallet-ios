import ComposableArchitecture
import SwiftUI

public extension Home {
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

public extension Home.View {
	var body: some View {
		VStack {
			Home.Header.View(
				store: store.scope(
					state: \.header,
					action: Home.Action.header
				)
			)
			Spacer()
			Home.AggregatedValue.View(
				store: store.scope(
					state: \.aggregatedValue,
					action: Home.Action.aggregatedValue
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
struct HomeView_Previews: PreviewProvider {
	static var previews: some View {
		Home.View(
			store: .init(
				initialState: .init(),
				reducer: Home.reducer,
				environment: .init()
			)
		)
	}
}
