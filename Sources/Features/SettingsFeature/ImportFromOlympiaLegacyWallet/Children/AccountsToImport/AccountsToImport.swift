import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport
public struct AccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		public let alreadyImported: Set<OlympiaAccountToMigrate.ID>

		public init(
			scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			alreadyImported: Set<OlympiaAccountToMigrate.ID> = []
		) {
			self.scannedAccounts = scannedAccounts
			self.alreadyImported = alreadyImported
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
			// MARK: - OlympiaAccountsToImport
			public struct OlympiaAccountsToImport: Sendable, Hashable {
				public let software: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?
				public let hardware: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>?

				init(selectedAccounts all: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>) {
					let software = NonEmpty(rawValue: OrderedSet(all.filter { $0.accountType == .software }))
					let hardware = NonEmpty(rawValue: OrderedSet(all.filter { $0.accountType == .hardware }))
					self.software = software
					self.hardware = hardware

					if software == nil, hardware == nil {
						let error = "Bad implementation, software AND hardware accounts cannot be both empty."
						loggerGlobal.critical(.init(stringLiteral: error))
						assertionFailure(error)
					}
				}
			}
		case .continueButtonTapped:
			return .send(.delegate(.continueImport))
		}
	}
}
