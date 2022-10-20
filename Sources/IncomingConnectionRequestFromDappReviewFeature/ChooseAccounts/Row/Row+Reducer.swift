import ComposableArchitecture

/// Namespace for Row
public extension ChooseAccounts {
    struct Row: ReducerProtocol {
        public init() {}
    }
}

public extension ChooseAccounts.Row {
    func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
        switch action {
        case .internal(.user(.accountTapped)):
            state.isSelected.toggle()
            return .none
        }
    }
}
