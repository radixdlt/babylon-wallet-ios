import FeaturePrelude

// MARK: - SelectAccountsToImport
public struct SelectAccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>
		public init(scannedAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>) {
			self.scannedAccounts = scannedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedAccounts(NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
