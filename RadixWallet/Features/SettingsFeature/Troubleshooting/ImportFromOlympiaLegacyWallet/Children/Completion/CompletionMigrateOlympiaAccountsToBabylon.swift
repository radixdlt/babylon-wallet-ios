import ComposableArchitecture
import SwiftUI

// MARK: - CompletionMigrateOlympiaAccountsToBabylon
struct CompletionMigrateOlympiaAccountsToBabylon: FeatureReducer {
	struct State: Hashable {
		let previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount]
		let migrated: IdentifiedArrayOf<Account>

		init(
			previouslyMigrated: [ImportOlympiaWalletCoordinator.MigratableAccount],
			migrated: IdentifiedArrayOf<Account>
		) {
			self.previouslyMigrated = previouslyMigrated
			self.migrated = migrated
		}
	}

	enum ViewAction: Equatable {
		case closeButtonTapped
		case accountListButtonTapped
	}

	enum DelegateAction: Equatable {
		case finishedMigration(gotoAccountList: Bool)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.send(.delegate(.finishedMigration(gotoAccountList: false)))

		case .accountListButtonTapped:
			.send(.delegate(.finishedMigration(gotoAccountList: true)))
		}
	}
}
