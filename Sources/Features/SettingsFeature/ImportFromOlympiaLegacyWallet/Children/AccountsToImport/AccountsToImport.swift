import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport
public struct AccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>

		public init(
			scannedAccounts: NonEmptyArray<ImportOlympiaWalletCoordinator.MigratableAccount>
		) {
			self.scannedAccounts = scannedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case viewAppeared
		case continueImport
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .send(.delegate(.viewAppeared))

		case .continueButtonTapped:
			return .send(.delegate(.continueImport))
		}
	}
}
