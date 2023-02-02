import FeaturePrelude
import ProfileClient

// MARK: - NewProfile
public struct NewProfile: Sendable, ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.errorQueue) var errorQueue
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.appeared)):
			return .run { send in
				await send(.internal(.system(.createProfileResult(TaskResult {
					try await profileClient.createNewProfile()
				}))))
			}

		case let .internal(.system(.createProfileResult(.success(factorSource)))):
			return .run { send in
				await send(.delegate(.createdProfile(factorSource: factorSource)))
			}

		case let .internal(.system(.createProfileResult(.failure(error)))):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.criticalFailureCouldNotCreateProfile))
			}

		case .delegate:
			return .none
		}
	}
}
