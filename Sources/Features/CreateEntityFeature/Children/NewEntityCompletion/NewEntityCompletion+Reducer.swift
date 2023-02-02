import FeaturePrelude

// MARK: - NewEntityCompletion
public struct NewEntityCompletion<Entity: EntityProtocol & Sendable & Equatable>: Sendable, ReducerProtocol {
	public init() {}
}

public extension NewEntityCompletion {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.goToDestination)):
			return .run { send in
				await send(.delegate(.completed))
			}

		case .delegate:
			return .none
		}
	}
}
