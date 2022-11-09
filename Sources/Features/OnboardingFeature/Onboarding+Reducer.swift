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
			case .internal(.user(.newProfile)):
				state.newProfile = .init()
				return .none

			case .internal(.user(.importProfile)):
				state.importProfile = .init()
				return .none

			case .importProfile(.coordinate(.goBack)):
				state.importProfile = nil
				return .none

			case let .importProfile(.coordinate(.failedToImportProfileSnapshot(importFailureReason))):
				return .run { send in
					await send(.coordinate(.failedToCreateOrImportProfile(reason: "Import failed: \(importFailureReason)")))
				}

			case let .importProfile(.coordinate(.importedProfileSnapshot(profileSnapshot))):
				return .run { send in
					await send(.internal(.coordinate(.importMnemonicForProfileSnapshot(profileSnapshot))))
				}

			case let .internal(.coordinate(.importMnemonicForProfileSnapshot(profileSnapshot))):
				state.importMnemonic = .init(importedProfileSnapshot: profileSnapshot)
				return .none

			case .newProfile(.coordinate(.goBack)):
				state.newProfile = nil
				return .none

			case let .newProfile(.coordinate(.finishedCreatingNewProfile(newProfile))):
				return .run { send in
					await send(.coordinate(.onboardedWithProfile(newProfile, isNew: true)))
				}

			case let .newProfile(.coordinate(.failedToCreateNewProfile(reason))):
				return .run { send in
					await send(.coordinate(.failedToCreateOrImportProfile(reason: "Failed to create profile: \(reason)")))
				}

			case .importMnemonic(.delegate(.goBack)):
				state.importMnemonic = nil
				return .none

			case let .importMnemonic(.delegate(.failedToImportMnemonicOrProfile(importFailureReason))):
				return .run { send in
					await send(.coordinate(.failedToCreateOrImportProfile(reason: "Import mnemonic failed: \(importFailureReason)")))
				}
			case let .importMnemonic(.delegate(.finishedImporting(_, profile))):
				return .run { send in
					await send(.coordinate(.onboardedWithProfile(profile, isNew: false)))
				}

			case .importProfile(.internal):
				return .none

			case .importMnemonic(.internal):
				return .none

			case .newProfile(.internal):
				return .none

			case .coordinate:
				return .none
			}
		}
		.ifLet(\.newProfile, action: /Action.newProfile) {
			NewProfile()
		}
		.ifLet(\.importProfile, action: /Action.importProfile) {
			ImportProfile()
		}
		.ifLet(\.importMnemonic, action: /Action.importMnemonic) {
			ImportMnemonic()
		}
	}
}
