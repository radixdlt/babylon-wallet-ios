import FeaturePrelude

// MARK: - NewEntityCompletion
public struct NewEntityCompletion<Entity: EntityProtocol & Sendable & Equatable, Destination: CreateEntityCompletionDestinationProtocol>: Sendable, ReducerProtocol {
	public init() {}
}

public extension NewEntityCompletion {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
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
