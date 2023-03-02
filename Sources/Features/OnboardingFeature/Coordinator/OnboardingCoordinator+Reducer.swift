import CreateEntityFeature
import FeaturePrelude

// MARK: - OnboardingCoordinator
public struct OnboardingCoordinator: Sendable, FeatureReducer {
	public enum State: Sendable, Hashable {
		case importProfile(ImportProfile.State)
		case createAccountCoordinator(CreateAccountCoordinator.State)

		public init(ephemeralPrivateProfile: Profile.Ephemeral.Private) {
			self = .createAccountCoordinator(
				.init(
					config: .init(
						specificGenesisFactorInstanceDerivationStrategy: .useEphemeralPrivateProfile(ephemeralPrivateProfile),
						isFirstEntity: true,
						canBeDismissed: false,
						navigationButtonCTA: .goHome
					)
				)
			)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case importProfile(ImportProfile.Action)
		case createAccountCoordinator(CreateAccountCoordinator.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
	}

	public enum InternalAction: Sendable, Equatable {
		case commitEphemeralResult(TaskResult<EquatableVoid>)
	}

	@Dependency(\.onboardingClient) var onboardingClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/OnboardingCoordinator.State.importProfile,
				action: /Action.child .. ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/OnboardingCoordinator.State.createAccountCoordinator,
				action: /Action.child .. ChildAction.createAccountCoordinator
			) {
				CreateAccountCoordinator()
			}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .commitEphemeralResult(.success):
			return .send(.delegate(.completed))
		case let .commitEphemeralResult(.failure(error)):
			fatalError("Unable to use app, failed to commit profile, error: \(String(describing: error))")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .createAccountCoordinator(.delegate(.completed)):
			return .run { send in
				await send(.internal(.commitEphemeralResult(TaskResult {
					try await onboardingClient.commitEphemeral()
				})))
			}
		case .importProfile(.delegate(.imported)):
			return .send(.delegate(.completed))
		default: return .none
		}
	}
}

#if DEBUG
extension OnboardingCoordinator.State {
	public static let previewValue: Self = {
		fatalError("impl me")
	}()
}
#endif
