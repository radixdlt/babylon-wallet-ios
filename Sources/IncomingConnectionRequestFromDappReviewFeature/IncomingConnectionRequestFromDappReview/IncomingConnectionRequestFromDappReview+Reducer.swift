import ComposableArchitecture

// MARK: - IncomingConnectionRequestFromDappReview
public struct IncomingConnectionRequestFromDappReview: ReducerProtocol {
	public init() {}
}

public extension IncomingConnectionRequestFromDappReview {
	func reduce(into _: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.user(.dismissIncomingConnectionRequest)):
			return .run { send in
				await send(.coordinate(.dismissIncomingConnectionRequest))
			}
		case .coordinate:
			return .none
		}
	}
}
