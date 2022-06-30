import ComposableArchitecture

/// Namespace for AppFeature
public enum App {}

// MARK: State
public extension App {
    struct State: Equatable {
        public init() {}
    }
}

// MARK: Action
public extension App {
    enum Action: Equatable {
        case noop // removes warnings
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
        // nothing to do
        return .none
    }
}

