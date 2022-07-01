//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import Profile
import ProfileLoader
import SwiftUI
import Wallet
import WalletLoader

public extension Splash {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Splash.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
		init(state _: Splash.State) {}
	}
}

internal extension Splash.Coordinator {
	// MARK: ViewAction
	enum ViewAction {
		case viewDidAppear
	}
}

internal extension Splash.Action {
	init(action: Splash.Coordinator.ViewAction) {
		switch action {
		case .viewDidAppear:
			self = .internal(.system(.viewDidAppear))
		}
	}
}

public extension Splash.Coordinator {
	// MARK: Body
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Splash.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Splash")
				}
			}
			.onAppear {
				viewStore.send(.viewDidAppear)
			}
		}
	}
}

// MARK: - SplashCoordinator_Previews
#if DEBUG
struct SplashCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Splash.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Splash.reducer,
				environment: .init(
					backgroundQueue: .immediate,
					mainQueue: .immediate,
					profileLoader: .noop,
					walletLoader: .noop
				)
			)
		)
	}
}
#endif // DEBUG
