import FeaturePrelude
import Profile

// MARK: - CompletionMigrateOlympiaAccountsToBabylon
public struct CompletionMigrateOlympiaAccountsToBabylon: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount]
		public let migrated: IdentifiedArrayOf<Profile.Network.Account>

		public init(
			previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount],
			migrated: IdentifiedArrayOf<Profile.Network.Account>
		) {
			self.previouslyMigrated = previouslyMigrated
			self.migrated = migrated
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case accountListButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration(gotoAccountList: Bool)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .send(.delegate(.finishedMigration(gotoAccountList: false)))

		case .accountListButtonTapped:
			return .send(.delegate(.finishedMigration(gotoAccountList: true)))
		}
	}
}
