import ComposableArchitecture
import HomeFeature
import SettingsFeature
import SwiftUI

public extension Main {
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
					action: Main.Action.home
				)
			)
			.zIndex(0)

			IfLetStore(
				store.scope(
					state: \.settings,
					action: Main.Action.settings
				),
				then: Settings.View.init(store:)
			)
			.zIndex(1)
		}
	}
}

extension Main.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var profileName: String

		init(state _: Main.State) {
//			profileName = state.wallet.profile.name
			// FIXME: wallet
			profileName = "placeholder"
		}
	}
}

extension Main.View {
	// MARK: ViewAction
	enum ViewAction {
		case removeWalletButtonPressed
	}
}

extension Main.Action {
	init(action: Main.View.ViewAction) {
		switch action {
		case .removeWalletButtonPressed:
			self = .internal(.user(.removeWallet))
		}
	}
}

// MARK: - MainView_Previews
struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		Main.View(
			store: .init(
				initialState: .placeholder,
				reducer: Main.reducer,
				environment: .init(
					accountWorthFetcher: .mock,
					appSettingsClient: .mock,
					pasteboardClient: .noop,
					userDefaultsClient: .noop
				)
			)
		)
	}
}
