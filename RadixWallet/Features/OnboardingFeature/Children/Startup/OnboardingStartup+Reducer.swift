import ComposableArchitecture
import SwiftUI

struct OnboardingStartup: FeatureReducer {
	struct State: Hashable {
		@PresentationState
		var destination: Destination.State?

		init() {}
	}

	enum ViewAction: Equatable {
		case selectedNewWalletUser
		case selectedRestoreFromBackup
	}

	enum DelegateAction: Equatable {
		case setupNewUser
		case profileCreatedFromImportedBDFS
		case completed
	}

	struct Destination: DestinationReducer {
		enum State: Hashable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.State)
		}

		enum Action: Equatable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.restoreFromBackup, action: /Action.restoreFromBackup) {
				RestoreProfileFromBackupCoordinator()
			}
		}
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	@Dependency(\.userDefaults) var userDefaults

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .selectedNewWalletUser:
			return .send(.delegate(.setupNewUser))

		case .selectedRestoreFromBackup:
			state.destination = .restoreFromBackup(.init())
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .restoreFromBackup(.delegate(.profileImported)):
			return .send(.delegate(.completed))

		case .restoreFromBackup(.delegate(.failedToImportProfileDueToMnemonics)):
			return .none

		case .restoreFromBackup(.delegate(.backToStartOfOnboarding)):
			state.destination = nil
			return .none

		case .restoreFromBackup(.delegate(.profileCreatedFromImportedBDFS)):
			state.destination = nil
			return .send(.delegate(.profileCreatedFromImportedBDFS))

		default:
			return .none
		}
	}
}
