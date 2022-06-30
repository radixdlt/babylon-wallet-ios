import ComposableArchitecture
import SwiftUI

// MARK: - App
/// Namespace for AppFeature
public enum App {}

public extension App {
	// MARK: State
	struct State: Equatable {
		public var alert: AlertState<Action>?
		public var counter: Int

		public init(
			alert: AlertState<Action>? = nil,
			counter: Int = 3
		) {
			self.alert = alert
			self.counter = counter
		}
	}
}

public extension App {
	// MARK: Action
	enum Action: Equatable {
		case alertDismissed
		case increaseCounter
		case decreaseCounter
	}
}

public extension App {
	// MARK: Environment
	struct Environment {
		public init() {}
	}
}

public extension App {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { state, action, _ in
		switch action {
		case .increaseCounter:
			state.counter += 1
			return .none
		case .decreaseCounter:
			if state.counter == 0 {
				state.alert = .init(title: TextState("Counter must not be negative"))
			} else {
				state.counter -= 1
			}
			return .none
		case .alertDismissed:
			state.alert = nil
			return .none
		}
	}
	.debug()
}

public extension App {
	// MARK: View
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>

		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

internal extension App.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		let counter: Int
		init(state: App.State) {
			counter = state.counter
		}
	}
}

internal extension App.View {
	// MARK: ViewAction
	enum ViewAction {
		case decreaseCounterButtonTapped
		case increaseCounterButtonTapped
	}
}

internal extension App.Action {
	init(action: App.View.ViewAction) {
		switch action {
		case .increaseCounterButtonTapped:
			self = .increaseCounter
		case .decreaseCounterButtonTapped:
			self = .decreaseCounter
		}
	}
}

public extension App.View {
	// MARK: Body
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: App.Action.init
			)
		) { viewStore in
			VStack {
				Text("Hello world!")
				Text("Counter: \(viewStore.counter)")
				Button("Increase counter") {
					viewStore.send(.increaseCounterButtonTapped)
				}
				Button("Decrease counter") {
					viewStore.send(.decreaseCounterButtonTapped)
				}
			}
			.alert(store.scope(state: \.alert), dismiss: .alertDismissed)
		}
	}
}

// MARK: - AppView_Previews
struct AppView_Previews: PreviewProvider {
	static var previews: some View {
		App.View(
			store: .init(
				initialState: .init(counter: 7),
				reducer: App.reducer,
				environment: .init()
			)
		)
	}
}
