import Common
import ComposableArchitecture
import Foundation
import HomeFeature
import SettingsFeature
import SwiftUI
import UserDefaultsClient
import Wallet

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

		init(state: Main.State) {
			profileName = state.wallet.profile.name
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
				initialState: .init(wallet: .init(profile: .init())),
				reducer: Main.reducer,
				environment: .init(
					backgroundQueue: .immediate,
					mainQueue: .immediate,
					userDefaultsClient: .noop
				)
			)
		)
	}
}
