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
				let request = CreateOnboardingWalletRequest()
				await send(.internal(.system(.createOnboardingWalletResult(TaskResult {
					try await profileClient.createOnboardingWallet(request)
				}))))
			}

		case let .internal(.system(.createOnboardingWalletResult(.success(onboardingWallet)))):
			return .run { send in
				await send(.delegate(.createdOnboardingWallet(onboardingWallet)))
			}

		case let .internal(.system(.createOnboardingWalletResult(.failure(error)))):
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.criticalFailureCouldNotCreateProfile))
			}

		case .delegate:
			return .none
		}
	}
}
