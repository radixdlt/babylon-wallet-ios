import ComposableArchitecture
import SwiftUI

// MARK: - CompletionMigrateOlympiaAccountsToBabylon
public struct CompletionMigrateOlympiaAccountsToBabylon: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount]
		public let migrated: IdentifiedArrayOf<Account>

		public init(
			previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount],
			migrated: IdentifiedArrayOf<Account>
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.finishedMigration(gotoAccountList: false)))

		case .accountListButtonTapped:
			.send(.delegate(.finishedMigration(gotoAccountList: true)))
		}
	}
}
