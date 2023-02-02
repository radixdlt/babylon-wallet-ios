import FeaturePrelude

// MARK: - CreateProfileCoordinator
public struct CreateProfileCoordinator: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifCaseLet(
				/CreateProfileCoordinator.State.importProfile,
				action: /Action.child .. Action.ChildAction.importProfile
			) {
				ImportProfile()
			}
			.ifCaseLet(
				/CreateProfileCoordinator.State.newProfile,
				action: /Action.child .. Action.ChildAction.newProfile
			) {
				NewProfile()
			}
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.newProfile(.delegate(.createdProfile(_)))):
			return .run { send in
				await send(.delegate(.completedWithProfile))
			}
		case .child(.newProfile(.delegate(.criticalFailureCouldNotCreateProfile))):
			return .run { send in
				await send(.delegate(.criticalFailureCouldNotCreateProfile))
			}

		case .child(.importProfile(.delegate(.imported))):
			return .run { send in
				await send(.delegate(.completedWithProfile))
			}
		default:
			return .none
		}
	}
}
