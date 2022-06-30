import ComposableArchitecture
import SwiftUI

/// Namespace for AppFeature
public enum App {}

// MARK: State
public extension App {
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

// MARK: Action
public extension App {
    enum Action: Equatable {
        case alertDismissed
        case increaseCounter
        case decreaseCounter
    }
}

// MARK: Environment
public extension App {
    struct Environment {
        public init() {}
    }
}

// MARK: Reducer
public extension App {
    typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
    static let reducer = Reducer { state, action, environment in
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

// MARK: View
public extension App {
    
    struct View: SwiftUI.View {
        public typealias Store = ComposableArchitecture.Store<State, Action>
        
        private let store: Store
        
        public init(store: Store) {
            self.store = store
        }
    }
}

// MARK: ViewState
internal extension App.View {
    struct ViewState: Equatable {
        let counter: Int
        init(state: App.State) {
            self.counter = state.counter
        }
    }
}

// MARK: ViewAction
internal extension App.View {
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

// MARK: Body (View)
public extension App.View {
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
