import ComposableArchitecture
import SwiftUI
public struct OnboardingStartup: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destination_.State?

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

	public struct Destination_: DestinationReducer {
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
			.ifLet(\.$destination, action: /Action.destination) {
				Destination_()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .selectedNewWalletUser:
			return .send(.delegate(.setupNewUser))

		case .selectedRestoreFromBackup:
			state.destination = .restoreFromBackup(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .destination(.presented(.restoreFromBackup(.delegate(.profileImported)))):
			.send(.delegate(.completed))

		case .destination(.presented(.restoreFromBackup(.delegate(.failedToImportProfileDueToMnemonics)))):
			.none

		default:
			.none
		}
	}
}
