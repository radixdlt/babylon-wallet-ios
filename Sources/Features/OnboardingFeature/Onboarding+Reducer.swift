import ComposableArchitecture
import ImportProfileFeature

// MARK: - Onboarding
public struct Onboarding: ReducerProtocol {
	public init() {}
}

public extension Onboarding {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.importProfile, action: /Action.child .. Action.ChildAction.importProfile) {
				ImportProfile()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.importProfileButtonTapped)):
			state.importProfile = .init()
			return .none

		case .child(.importProfile(.delegate(.goBack))):
			state.importProfile = nil
			return .none

		case let .child(.importProfile(.delegate(.importedProfileSnapshot(profileSnapshot)))):
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
