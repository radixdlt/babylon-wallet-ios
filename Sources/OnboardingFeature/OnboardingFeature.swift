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
import UserDefaultsClient
import Wallet

// MARK: - Onboarding
/// Namespace for OnboardingFeature
public enum Onboarding {}

public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		// Just for initial testing
		@BindableState public var profileName: String
		public var canProceed: Bool

		public init(
			profileName: String = "",
			canProceed: Bool = false
		) {
			self.profileName = profileName
			self.canProceed = canProceed
		}
	}
}

public extension Onboarding {
	// MARK: Action
	enum Action: Equatable, BindableAction {
		case binding(BindingAction<State>)
		case coordinate(CoordinatingAction)
		case `internal`(InternalAction)
	}
}

public extension Onboarding.Action {
	enum CoordinatingAction: Equatable {
		case onboardedWithWallet(Wallet)
	}
}

public extension Onboarding.Action {
	enum InternalAction: Equatable {
		case user(UserAction)
		case system(SystemAction)
	}
}

public extension Onboarding.Action.InternalAction {
	enum UserAction: Equatable {
		case createWallet
	}
}

public extension Onboarding.Action.InternalAction {
	enum SystemAction: Equatable {
		case createWallet
		case createWalletResult(Result<Wallet, Never>)
	}
}

public extension Onboarding {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let userDefaultsClient: UserDefaultsClient // replace with `ProfileCreator`
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

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, environment in
		switch action {
		case .coordinate:
			return .none
		case .internal(.user(.createWallet)):
			return Effect(value: .internal(.system(.createWallet)))
		case .internal(.system(.createWallet)):
			precondition(state.canProceed)
			let profile = Profile(name: state.profileName)
			let wallet = Wallet(profile: profile)

			return .concatenate(
				environment
					.userDefaultsClient
					.setProfileName(state.profileName)
					.subscribe(on: environment.backgroundQueue)
					.receive(on: environment.mainQueue)
					.fireAndForget(),

				Effect(value: .internal(.system(.createWalletResult(.success(wallet)))))
			)

		case let .internal(.system(.createWalletResult(.success(wallet)))):
			return Effect(value: .coordinate(.onboardedWithWallet(wallet)))
		case .binding:
			state.canProceed = !state.profileName.isEmpty
			return .none
		}
	}
	.binding()
}

public extension Onboarding {
	struct Coordinator: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension Onboarding.Coordinator {
	// MARK: ViewState
	struct ViewState: Equatable {
		@BindableState var profileName: String
		var canProceed: Bool
		init(
			state: Onboarding.State
		) {
			profileName = state.profileName
			canProceed = state.canProceed
		}
	}
}

internal extension Onboarding.Coordinator {
	// MARK: ViewAction
	enum ViewAction: Equatable, BindableAction {
		case binding(BindingAction<ViewState>)
		case createWalletButtonPressed
	}
}

private extension Onboarding.State {
	var view: Onboarding.Coordinator.ViewState {
		get { .init(state: self) }
		set {
			// handle bindable actions only:
			profileName = newValue.profileName
			canProceed = newValue.canProceed
		}
	}
}

internal extension Onboarding.Action {
	init(action: Onboarding.Coordinator.ViewAction) {
		switch action {
		case let .binding(bindingAction):
			self = .binding(
				bindingAction.pullback(\Onboarding.State.view)
			)
		case .createWalletButtonPressed:
			self = .internal(.user(.createWallet))
		}
	}
}

public extension Onboarding.Coordinator {
	// MARK: Body
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Onboarding.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					TextField("Profile Name", text: viewStore.binding(\.$profileName))
					Button("Create wallet") {
						viewStore.send(.createWalletButtonPressed)
					}
					.disabled(!viewStore.canProceed)
				}
			}
		}
	}
}

// MARK: - OnboardingCoordinator_Previews
#if DEBUG
struct OnboardingCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Onboarding.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Onboarding.reducer,
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
