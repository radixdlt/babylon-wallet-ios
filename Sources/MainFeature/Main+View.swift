import Common
import ComposableArchitecture
import Foundation
import HomeFeature
import SettingsFeature
import SwiftUI
import UserDefaultsClient
import Wallet

public extension Main {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Main.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
		public var profileName: String
		init(state: Main.State) {
			profileName = state.wallet.profile.name
		}
	}
}

internal extension Main.Coordinator {
	// MARK: ViewAction
	enum ViewAction {
		case removeWalletButtonPressed
	}
}

internal extension Main.Action {
	init(action: Main.Coordinator.ViewAction) {
		switch action {
		case .removeWalletButtonPressed:
			self = .internal(.user(.removeWallet))
		}
	}
}

public extension Main.Coordinator {
	// MARK: Body
	var body: some View {
		ZStack {
			Home.Coordinator(
				store: store.scope(state: \.home, action: Main.Action.home)
			)
			.zIndex(0)

			IfLetStore(
				store.scope(state: \.settings, action: Main.Action.settings),
				then: Settings.Coordinator.init(store:)
			)
			.zIndex(1)
		}
	}
}

// MARK: - MainCoordinator_Previews
#if DEBUG
struct MainCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Main.Coordinator(
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
#endif // DEBUG
