import ComposableArchitecture
import Converse

// MARK: - ConnectUsingSecrets
public struct ConnectUsingSecrets: Sendable, ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	public init() {}
}

public extension ConnectUsingSecrets {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):

			let connection = Connection.live(
				connectionSecrets: state.connectionSecrets
			)

			return .run { send in
				await send(.internal(.system(.establishConnectionResult(
					TaskResult {
						try await connection.establish()
						return connection
					}
				))))
			}

		case let .internal(.system(.establishConnectionResult(.success(connection)))):
			return .run { send in
				await send(.delegate(.connected(connection)))
			}

		case let .internal(.system(.establishConnectionResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case .delegate:
			return .none
		}
	}
}
