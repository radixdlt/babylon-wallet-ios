//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import ComposableArchitecture
import HomeFeature
import MainFeature
import OnboardingFeature
import ProfileLoader
import SplashFeature
import SwiftUI
import UserDefaultsClient
import Wallet
import WalletLoader

public extension App {
	// MARK: Coordinator
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>

		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension App.Coordinator {
	// MARK: Body
	var body: some View {
		SwitchStore(store) {
			CaseLet(state: /App.State.main,
			        action: App.Action.main,
			        then: Main.Coordinator.init(store:))

			CaseLet(state: /App.State.onboarding,
			        action: App.Action.onboarding,
			        then: Onboarding.Coordinator.init(store:))

			CaseLet(state: /App.State.splash,
			        action: App.Action.splash,
			        then: Splash.Coordinator.init(store:))
		}
	}
}

// MARK: - AppCoordinator_Previews
#if DEBUG
struct AppCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		App.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: App.reducer,
				environment: .noop
			)
		)
	}
}

#endif // DEBUG
