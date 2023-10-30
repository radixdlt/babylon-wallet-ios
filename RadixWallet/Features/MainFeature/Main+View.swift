import ComposableArchitecture
import SwiftUI
extension Main.State {
	public var showIsUsingTestnetBanner: Bool {
		!isOnMainnet
	}
}

// MARK: - Main.View
extension Main {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<Main>

		public init(store: StoreOf<Main>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			let bannerStore = store.scope(state: \.showIsUsingTestnetBanner, action: actionless)
			NavigationStack {
				Home.View(
					store: store.scope(
						state: \.home,
						action: { .child(.home($0)) }
					)
				)
				.navigationBarBackButtonFont(.app.backButton)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.navigationBarTitleColor(.app.gray1)
				.navigationDestination(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /Main.Destinations.State.settings,
					action: Main.Destinations.Action.settings,
					destination: { Settings.View(store: $0) }
				)
			}
			.navigationViewStyle(.stack)
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
			.showDeveloperDisclaimerBanner(bannerStore)
			.presentsDappInteractions()
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI
struct MainView_Previews: PreviewProvider {
	static var previews: some SwiftUI.View {
		Main.View(
			store: .init(
				initialState: .previewValue,
				reducer: Main.init
			)
		)
	}
}

extension Main.State {
	public static let previewValue = Self(home: .previewValue)
}
#endif
