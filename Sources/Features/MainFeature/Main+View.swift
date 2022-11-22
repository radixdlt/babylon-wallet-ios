import ComposableArchitecture
import HomeFeature
import SettingsFeature
import SwiftUI

// MARK: - Main.View
public extension Main {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension Main.View {
	var body: some View {
		ZStack {
			Home.View(
				store: store.scope(
					state: \.home,
					action: { .child(.home($0)) }
				)
			)
			.zIndex(0)

			IfLetStore(
				store.scope(
					state: \.settings,
					action: { .child(.settings($0)) }
				),
				then: Settings.View.init(store:)
			)
			.zIndex(1)
		}
	}
}

//// MARK: - MainView_Previews
// struct MainView_Previews: PreviewProvider {
//	static var previews: some View {
//		Main.View(
//			store: .init(
//				initialState: .placeholder,
//				reducer: Main.reducer,
//				environment: .init(
//					accountPortfolioFetcher: .mock,
//					appSettingsClient: .mock,
//					keychainClient: .unimplemented,
//					pasteboardClient: .noop,
//					profileClient: .testValue
//				)
//			)
//		)
//	}
// }
