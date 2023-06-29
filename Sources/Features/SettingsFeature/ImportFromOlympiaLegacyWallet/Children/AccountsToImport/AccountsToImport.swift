import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport
public struct AccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>

		public init(
			scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			self.scannedAccounts = scannedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case continueImport
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .continueButtonTapped:
			return .send(.delegate(.continueImport))
		}
	}
}
