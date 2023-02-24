import CreateEntityFeature
import FeaturePrelude
import ProfileClient

// MARK: - NewProfileThenAccountCoordinator
public struct NewProfileThenAccountCoordinator: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.step, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Step.newProfile, action: /Action.child .. ChildAction.newProfile) {
					NewProfile()
				}
				.ifCaseLet(/State.Step.createAccountCoordinator, action: /Action.child .. ChildAction.createAccountCoordinator) {
					CreateAccountCoordinator()
				}
		}
		Reduce(self.core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .newProfile(.delegate(.createdEphemeralPrivateProfile(ephemeralPrivateProfile))):
			state.ephemeralPrivateProfile = ephemeralPrivateProfile

			state.step = .createAccountCoordinator(.init(
				config: .init(
					specificGenesisFactorInstanceDerivationStrategy: .useEphemeralPrivateProfile(ephemeralPrivateProfile),
					isFirstEntity: true,
					canBeDismissed: false,
					navigationButtonCTA: .goHome
				)
			))
			return .none

		case .newProfile(.delegate(.criticalFailureCouldNotCreateProfile)):
			fatalError("Failed to create new profile, what to do other than crash..?")

		case .createAccountCoordinator(.delegate(.completed)):
			guard let ephemeralPrivateProfile = state.ephemeralPrivateProfile else {
				assertionFailure("incorrect implementation")
				return .none
			}

			return .run { send in
				await send(.internal(.commitEphemeralPrivateProfile(TaskResult {
					try await profileClient.commitEphemeralPrivateProfile(ephemeralPrivateProfile)
				})))
			}
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .commitEphemeralPrivateProfile(.success):
			return .run { send in
				await send(.delegate(.completed))
			}
		case let .commitEphemeralPrivateProfile(.failure(error)):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.criticialErrorFailedToCommitEphemeralProfile))
			}
		}
	}
}
