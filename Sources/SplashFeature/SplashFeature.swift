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
import SwiftUI
import Wallet

// MARK: - Splash
/// Namespace for SplashFeature
public enum Splash {}

public extension Splash {
	// MARK: State
	struct State: Equatable {
		public init() {}
	}
}

public extension Splash {
	// MARK: Action
	enum Action: Equatable {
		case `internal`(InternalAction)
		case coordinate(CoordinatingAction)
	}
}

public extension Splash.Action {
	enum CoordinatingAction: Equatable {
		case walletLoaded(Wallet)
		case secretsNotFoundForProfile(Profile)
	}
}

// MARK: - PlaceholderError
public enum PlaceholderError: Swift.Error, Equatable {}

public extension Splash.Action {
	enum InternalAction: Equatable {
		case system(SystemAction)
	}
}

public extension Splash.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadProfile
		case loadProfileResult(Result<Profile, PlaceholderError>)
		case loadWallet
		case loadWalletResult(Result<Wallet, PlaceholderError>)
		case viewLifeCycle(ViewLifeCycleAction)
	}
}

public extension Splash.Action.InternalAction.SystemAction {
	enum ViewLifeCycleAction: Equatable {
		case viewDidAppear
	}
}

public extension Splash {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
		}
	}
}

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.system(.viewLifeCycle(.viewDidAppear))):
			fatalError()
		case .coordinate: break
		default:
			fatalError()
		}
		return .none
	}
}

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
		case noop
	}
}

internal extension Splash.Action {
	init(action _: Splash.Coordinator.ViewAction) {
//		switch action {
//		case .noop:
//			fat
//		}
		fatalError()
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
		) { _ in
			ForceFullScreen {
				VStack {
					Text("Splash")
				}
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
					mainQueue: .immediate
				)
			)
		)
	}
}
#endif // DEBUG
