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

			case let .importProfile(.coordinate(.importedProfile(profile))):
				return .run { send in
					await send(.coordinate(.onboardedWithProfile(profile, isNew: false)))
				}

			case .newProfile(.coordinate(.goBack)):
				state.newProfile = nil
				return .none

			case let .newProfile(.coordinate(.finishedCreatingNewProfile(newProfile))):
				return .run { send in
					await send(.coordinate(.onboardedWithProfile(newProfile, isNew: true)))
				}

			case .importProfile(.internal):
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
	}
}
