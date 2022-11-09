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
	var body: some ReducerProtocol<State, Action> {
		Reduce { state, action in
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

			case let .child(.importProfile(.delegate(.failedToImportProfileSnapshot(importFailureReason)))):
				return .run { send in
					await send(.delegate(.failedToCreateOrImportProfile(reason: "Import failed: \(importFailureReason)")))
				}

			case let .child(.importProfile(.delegate(.importedProfileSnapshot(profileSnapshot)))):
				state.importMnemonic = .init(importedProfileSnapshot: profileSnapshot)
				return .none

			case .child(.newProfile(.delegate(.goBack))):
				state.newProfile = nil
				return .none

			case let .child(.newProfile(.delegate(.finishedCreatingNewProfile(newProfile)))):
				return .run { send in
					await send(.delegate(.onboardedWithProfile(newProfile, isNew: true)))
				}

			case let .child(.newProfile(.delegate(.failedToCreateNewProfile(reason)))):
				return .run { send in
					await send(.delegate(.failedToCreateOrImportProfile(reason: "Failed to create profile: \(reason)")))
				}

			case .child(.importMnemonic(.delegate(.goBack))):
				state.importMnemonic = nil
				return .none

			case let .child(.importMnemonic(.delegate(.failedToImportMnemonicOrProfile(importFailureReason)))):
				return .run { send in
					await send(.delegate(.failedToCreateOrImportProfile(reason: "Import mnemonic failed: \(importFailureReason)")))
				}

			case let .child(.importMnemonic(.delegate(.finishedImporting(_, profile)))):
				return .run { send in
					await send(.delegate(.onboardedWithProfile(profile, isNew: false)))
				}

			case .child, .delegate:
				return .none
			}
		}
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
}
