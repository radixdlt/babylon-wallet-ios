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

// MARK: - Main
/// Namespace for MainFeature
public enum Main {}

public extension Main {
	// MARK: State
	struct State: Equatable {
		public init() {}
	}
}

public extension Main {
	// MARK: Action
	enum Action: Equatable {
		case noop // removes warning
	}
}

public extension Main {
	// MARK: Environment
	struct Environment: Equatable {
		public init() {}
	}
}

public extension Main {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .noop:
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
		init(state _: Main.State) {}
	}
}

internal extension Main.Coordinator {
	// MARK: ViewAction
	enum ViewAction {
		case noop
	}
}

internal extension Main.Action {
	init(action: Main.Coordinator.ViewAction) {
		switch action {
		case .noop:
			self = .noop
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
			ForceFullScreen {
				VStack {
					Text("Main")
				}
			}
		}
	}
}

// MARK: - MainCoordinator_Previews
struct MainCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		Main.Coordinator(
			store: .init(
				initialState: .init(),
				reducer: Main.reducer,
				environment: .init()
			)
		)
	}
}
