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
		HStack(alignment: .top) {
			GeometryReader { proxy in
				VStack {
					titleView
						.frame(width: proxy.size.width * 0.7)
					Spacer()
				}
			}
			.padding()
			Spacer()
		}
	}
}

private extension Home.Coordinator {
	var titleView: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("home_wallet_title")
				.textStyle(.primaryTitle)
			Text("home_wallet_subtitle")
				.textStyle(.secondary)
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
