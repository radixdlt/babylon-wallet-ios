import FeaturePrelude
import Profile

// MARK: - CompletionMigrateOlympiaAccountsToBabylon
public struct CompletionMigrateOlympiaAccountsToBabylon: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let previouslyMigratedAccounts: [OlympiaAccountToMigrate]
		public let migratedAccounts: Profile.Network.Accounts?
		public let unvalidatedOlympiaHardwareAccounts: Set<OlympiaAccountToMigrate>?
		public init(
			previouslyMigratedAccounts: [OlympiaAccountToMigrate],
			migratedAccounts: IdentifiedArrayOf<Profile.Network.Account>,
			unvalidatedOlympiaHardwareAccounts: Set<OlympiaAccountToMigrate>?
		) {
			self.previouslyMigratedAccounts = previouslyMigratedAccounts
			self.migratedAccounts = .init(rawValue: migratedAccounts)
			self.unvalidatedOlympiaHardwareAccounts = unvalidatedOlympiaHardwareAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case finishButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .finishButtonTapped:
			return .send(.delegate(.finishedMigration))
		}
	}
}
