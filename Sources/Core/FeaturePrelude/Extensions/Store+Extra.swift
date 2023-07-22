import ComposableArchitecture

extension Store: @unchecked Sendable where State == Void, Action: Sendable {}
