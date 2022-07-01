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
		case noop // removes warning
	}
}

public extension Splash {
	// MARK: Environment
	struct Environment: Equatable {
		public init() {}
	}
}

public extension Splash {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .noop:
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
		case noop
	}
}

internal extension Splash.Action {
	init(action: Splash.Coordinator.ViewAction) {
		switch action {
		case .noop:
			self = .noop
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
		) { _ in
			VStack {
				Text("Splash")
			}
		}
	}
}

// MARK: - SplashCoordinator_Previews
struct SplashCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Splash.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Splash.reducer,
				environment: .init()
			)
		)
	}
}
