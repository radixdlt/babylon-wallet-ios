//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import HomeFeature
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
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Main.Action.init
			)
		) { _ in
			IfLetStore(
				store.scope(state: \.home,
				            action: Main.Action.home),
				then: Home.Coordinator.init(store:)
			)
			/*
			 ForceFullScreen {
			 	VStack {
			 		Text("Welcome: \(viewStore.profileName)")
			 		Button("Remove Wallet") {
			 			viewStore.send(.removeWalletButtonPressed)
			 		}
			 	}
			 }
			 */
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
