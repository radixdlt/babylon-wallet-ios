//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-07-01.
//

import Common
import ComposableArchitecture
import Foundation
import SwiftUI
import UserDefaultsClient
import Wallet

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

public extension Main {
	// MARK: State
	struct State: Equatable {
		public var wallet: Wallet
		public init(wallet: Wallet) {
			self.wallet = wallet
		}
	}
}

public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalActions)
		case coordinate(CoordinatingAction)
	}
}

public extension Main.Action {
	enum InternalActions: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Main.Action.InternalActions {
	enum UserAction: Equatable {
		case removeWallet
	}
}

public extension Main.Action.InternalActions {
	enum SystemAction: Equatable {
		case removedWallet
	}
}

public extension Main.Action {
	enum CoordinatingAction: Equatable {
		case removedWallet
	}
}

public extension Main {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let userDefaultsClient: UserDefaultsClient
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			userDefaultsClient: UserDefaultsClient
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.userDefaultsClient = userDefaultsClient
		}
	}
}

public extension Main {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.user(.removeWallet)):
			return Effect(value: .internal(.system(.removedWallet)))

		case .internal(.system(.removedWallet)):
			return .concatenate(
				environment
					.userDefaultsClient
					.removeProfileName()
					.subscribe(on: environment.backgroundQueue)
					.receive(on: environment.mainQueue)
					.fireAndForget(),

				Effect(value: .coordinate(.removedWallet))
			)

		case .coordinate:
			return .none
		}
	}
}

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
		) { viewStore in
			ForceFullScreen {
				VStack {
					Text("Welcome: \(viewStore.profileName)")
					Button("Remove Wallet") {
						viewStore.send(.removeWalletButtonPressed)
					}
				}
			}
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
