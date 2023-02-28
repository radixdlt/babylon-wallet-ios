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
				let request = CreateEphemeralPrivateProfileRequest()
				await send(.internal(.system(.createEphemeralPrivateProfileResult(TaskResult {
					try await profileClient.createEphemeralPrivateProfile(request)
				}))))
			}

		case let .internal(.system(.createEphemeralPrivateProfileResult(.success(ephemeralPrivateProfile)))):
			return .run { send in
				await send(.delegate(.createdEphemeralPrivateProfile(ephemeralPrivateProfile)))
			}

		case let .internal(.system(.createEphemeralPrivateProfileResult(.failure(error)))):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.criticalFailureCouldNotCreateProfile))
			}

		case .delegate:
			return .none
		}
	}
}
