import ComposableArchitecture
import SwiftUI

// MARK: - AccountsToImport
struct AccountsToImport: FeatureReducer {
	struct State: Hashable {
		let scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>

		init(
			scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>
		) {
			self.scannedAccounts = scannedAccounts
		}
	}

	enum ViewAction: Equatable {
		case appeared
		case continueButtonTapped
	}

	enum DelegateAction: Equatable {
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
