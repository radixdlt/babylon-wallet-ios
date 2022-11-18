import ComposableArchitecture
import ImportProfileFeature
import Mnemonic
import Profile
import ProfileClient

// MARK: - Onboarding
public struct Onboarding: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.mainQueue) var mainQueue
	public init() {}
}

public extension Onboarding {
	var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.newProfile, action: /Action.child .. Action.ChildAction.newProfile) {
				NewProfile()
			}
			.ifLet(\.importProfile, action: /Action.child .. Action.ChildAction.importProfile) {
				ImportProfile()
			}
			.ifLet(\.importMnemonic, action: /Action.child .. Action.ChildAction.importMnemonic) {
				ImportMnemonic()
			}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.newProfileButtonTapped)):
			state.newProfile = .init()
			return .none

		case .internal(.view(.importProfileButtonTapped)):
			state.importProfile = .init()
			return .none

		case .child(.importProfile(.delegate(.goBack))):
			state.importProfile = nil
			return .none

		case let .child(.importProfile(.delegate(.importedProfileSnapshot(profileSnapshot)))):
			state.importMnemonic = .init(importedProfileSnapshot: profileSnapshot)
			return .none

		case .child(.newProfile(.delegate(.goBack))):
			state.newProfile = nil
			return .none

		case .child(.importMnemonic(.delegate(.goBack))):
			state.importMnemonic = nil
			return .none

		case .child, .delegate:
			return .none
		}
	}
}
