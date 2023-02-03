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
		case let .newProfile(.delegate(.createdProfile(unsavedProfile))):
			state.unsavedProfile = unsavedProfile

			state.step = .createAccountCoordinator(.init(
				config: .init(
					specificGenesisFactorInstanceDerivationStrategy: .useMnemonic(
						unsavedProfile.onDeviceFactorSourceMnemonic,
						forFactorSource: unsavedProfile.profile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first
					),
					isFirstEntity: true,
					canBeDismissed: false,
					navigationButtonCTA: .goHome
				)
			))
			return .none

		case .newProfile(.delegate(.criticalFailureCouldNotCreateProfile)):
			fatalError("Failed to create new profile, what to do other than crash..?")

		case .createAccountCoordinator(.delegate(.completed)):
			guard let unsavedProfileAndMnemonic = state.unsavedProfile else {
				assertionFailure("incorrect implementation")
				return .none
			}
			let request = CommitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicRequest(
				onDeviceFactorSourceMnemonic: unsavedProfileAndMnemonic.onDeviceFactorSourceMnemonic,
				bip39Passphrase: unsavedProfileAndMnemonic.request.bip39Passphrase
			)

			return .run { send in
				await send(.internal(.commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicResult(TaskResult {
					try await profileClient.commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonic(request)
				})))
			}
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicResult(.success):
			return .run { send in
				await send(.delegate(.completed))
			}
		case let .commitEphemeralProfileAndPersistOnDeviceFactorSourceMnemonicResult(.failure(error)):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.criticialErrorFailedToCommitEphemeralProfile))
			}
		}
	}
}
