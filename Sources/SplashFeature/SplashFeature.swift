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

// MARK: - SplashLoadWalletResult
public enum SplashLoadWalletResult: Equatable {
	case walletLoaded(Wallet)
	case noWallet(reason: NoWalletLoaded)

	public enum NoWalletLoaded: Equatable {
		case noProfileFoundAtPath(String)
		case failedToLoadProfileFromDocument
		case secretsNotFoundForProfile(Profile)
	}
}

public extension Splash.Action {
	enum CoordinatingAction: Equatable {
		case loadWalletResult(SplashLoadWalletResult)
	}
}

// MARK: - PlaceholderError
public enum PlaceholderError: Swift.Error, Equatable {}

public extension Splash.Action {
	enum InternalAction: Equatable {
		/// So we can use a single exit path, and `delay` to display this Splash for at
		/// least 500 ms or suitable time
		case coordinate(CoordinatingAction)

		case system(SystemAction)
	}
}

public extension Splash.Action.InternalAction {
	enum SystemAction: Equatable {
		case loadProfile
		case loadProfileResult(Result<Profile, ProfileLoader.Error>)
		case loadWalletWithProfile(Profile)
		case loadWalletWithProfileResult(Result<Wallet, WalletLoader.Error>, profile: Profile)

		case viewDidAppear
	}
}

public extension Splash {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let profileLoader: ProfileLoader
		public let walletLoader: WalletLoader
		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			profileLoader: ProfileLoader,
			walletLoader: WalletLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.profileLoader = profileLoader
			self.walletLoader = walletLoader
		}
	}
}

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, environment in
		switch action {
		case .internal(.system(.viewDidAppear)):
			return Effect(value: .internal(.system(.loadProfile)))
		case .internal(.system(.loadProfile)):
			return environment
				.profileLoader
				.loadProfile()
				.subscribe(on: environment.backgroundQueue)
				.receive(on: environment.mainQueue)
				.catchToEffect { Splash.Action.internal(.system(.loadProfileResult($0))) }

		case let .internal(.system(.loadProfileResult(.success(profile)))):
			return Effect(value: .internal(.system(.loadWalletWithProfile(profile))))
		case let .internal(.system(.loadProfileResult(.failure(.noProfileDocumentFoundAtPath(path))))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .noProfileFoundAtPath(path))))))
		case .internal(.system(.loadProfileResult(.failure(.failedToLoadProfileFromDocument)))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .failedToLoadProfileFromDocument)))))

		case let .internal(.system(.loadWalletWithProfile(profile))):
			return environment
				.walletLoader
				.loadWallet(profile)
				.subscribe(on: environment.backgroundQueue)
				.receive(on: environment.mainQueue)
				.catchToEffect { Splash.Action.internal(.system(.loadWalletWithProfileResult($0, profile: profile))) }

		case let .internal(.system(.loadWalletWithProfileResult(.success(wallet), _))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.walletLoaded(wallet)))))
		case let .internal(.system(.loadWalletWithProfileResult(.failure(.secretsNoFoundForProfile), profile))):
			return Effect(value: .internal(.coordinate(.loadWalletResult(.noWallet(reason: .secretsNotFoundForProfile(profile))))))
		case let .internal(.coordinate(actionToCoordinate)):
			return Effect(value: .coordinate(actionToCoordinate))
				.delay(for: 0.7, scheduler: environment.mainQueue)
				.eraseToEffect()
		case .coordinate:
			return .none
		}
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
