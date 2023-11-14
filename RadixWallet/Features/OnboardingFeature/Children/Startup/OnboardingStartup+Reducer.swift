import ComposableArchitecture
import SwiftUI
public struct OnboardingStartup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectedNewWalletUser
		case selectedRestoreFromBackup
	}

	public enum DelegateAction: Sendable, Equatable {
		case setupNewUser
		case completed
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.State)
		}

		public enum Action: Sendable, Equatable {
			case restoreFromBackup(RestoreProfileFromBackupCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.restoreFromBackup, action: /Action.restoreFromBackup) {
				RestoreProfileFromBackupCoordinator()
			}
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .selectedNewWalletUser:
			return .send(.delegate(.setupNewUser))

		case .selectedRestoreFromBackup:
			state.destination = .restoreFromBackup(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .restoreFromBackup(.delegate(.profileImported)):
			.send(.delegate(.completed))

		case .restoreFromBackup(.delegate(.failedToImportProfileDueToMnemonics)):
			.none

		default:
			.none
		}
	}
}
