//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import ComposableArchitecture
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
		ZStack {
			Text("<APP EMPTY STATE>") // Handle better, make App.State an enum?
				.foregroundColor(Color.red)
				.background(Color.yellow)
				.font(.largeTitle)
				.zIndex(0)

			IfLetStore(
				store.scope(state: \.main, action: App.Action.main),
				then: Main.Coordinator.init(store:)
			)
			.zIndex(1)

			IfLetStore(
				store.scope(state: \.onboarding, action: App.Action.onboarding),
				then: Onboarding.Coordinator.init(store:)
			)
			.zIndex(2)

			IfLetStore(
				store.scope(state: \.splash, action: App.Action.splash),
				then: Splash.Coordinator.init(store:)
			)
			.zIndex(3)
		}
		.alert(store.scope(state: \.alert), dismiss: .internal(.user(.alertDismissed)))
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
