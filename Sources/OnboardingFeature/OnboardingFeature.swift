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

// MARK: - Onboarding
/// Namespace for OnboardingFeature
public enum Onboarding {}

public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		public init() {}
	}
}

public extension Onboarding {
	// MARK: Action
	enum Action: Equatable {
		case noop // removes warning
	}
}

public extension Onboarding {
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

public extension Onboarding {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .noop:
			return .none
		}
	}
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
		init(state _: Onboarding.State) {}
	}
}

internal extension Onboarding.Coordinator {
	// MARK: ViewAction
	enum ViewAction {
		case noop
	}
}

internal extension Onboarding.Action {
	init(action: Onboarding.Coordinator.ViewAction) {
		switch action {
		case .noop:
			self = .noop
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
		) { _ in
			ForceFullScreen {
				VStack {
					Text("Onboarding")
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
					mainQueue: .immediate
				)
			)
		)
	}
}
#endif // DEBUG
