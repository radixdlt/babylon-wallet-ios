import ComposableArchitecture
import ImportProfileFeature
import CreateAccountFeature

// MARK: - Onboarding
public struct Onboarding: ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
        Scope(state: \.root, action: /Action.self) {
            EmptyReducer()
                .ifCaseLet(/Onboarding.State.Root.importProfile, action: /Action.child .. Action.ChildAction.importProfile) {
                    ImportProfile()
                }
                .ifCaseLet(/Onboarding.State.Root.createAccount, action: /Action.child .. Action.ChildAction.createAccount) {
                    CreateAccount()
                }
        }

        Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.importProfileButtonTapped)):
			return .none

		case .child(.importProfile(.delegate(.goBack))):
			return .none

		case let .child(.importProfile(.delegate(.importedProfileSnapshot(profileSnapshot)))):
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
