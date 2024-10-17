import ComposableArchitecture
import SwiftUI

// MARK: - AccountsToImport
struct AccountsToImport: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>

		init(
			scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>
		) {
			self.scannedAccounts = scannedAccounts
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case viewAppeared
		case continueImport
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.send(.delegate(.viewAppeared))

		case .continueButtonTapped:
			.send(.delegate(.continueImport))
		}
	}
}
