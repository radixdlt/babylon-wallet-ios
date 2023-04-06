import AccountsClient
import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - SelectAccountsToImport
public struct SelectAccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let availableAccounts: IdentifiedArrayOf<OlympiaAccountToMigrate>
		var selectedAccounts: [OlympiaAccountToMigrate]?
		public let selectionRequirement: SelectionRequirement = .atLeast(1)

		public init(
			scannedAccounts availableAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			selectedAccounts: [OlympiaAccountToMigrate]? = nil
		) {
			self.availableAccounts = IdentifiedArrayOf(uniqueElements: availableAccounts.rawValue.elements, id: \.id)
			self.selectedAccounts = selectedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectAll
		case deselectAll
		case selectedAccountsChanged([OlympiaAccountToMigrate]?)
		case continueButtonTapped([OlympiaAccountToMigrate])
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedAccounts(OlympiaAccountsToImport)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case .selectAll:
			state.selectedAccounts = .init(state.availableAccounts)
			return .none

		case .deselectAll:
			state.selectedAccounts = nil
			return .none

		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none

		case let .continueButtonTapped(selectedAccountsArray):
			guard
				case let selectedAccountsSet = OrderedSet(selectedAccountsArray),
				let selectedAccounts = NonEmpty<OrderedSet<OlympiaAccountToMigrate>>(rawValue: selectedAccountsSet)
			else {
				if state.selectionRequirement >= 1 {
					assertionFailure("Should not be possible to continue without having selected at least one account.")
				}
				return .none
			}

			return .send(.delegate(.selectedAccounts(
				OlympiaAccountsToImport(selectedAccounts: selectedAccounts)
			)))
		}
	}
}

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

extension SelectionRequirement {
	static func >= (lhs: Self, rhsQuantity: Int) -> Bool {
		switch lhs {
		case let .atLeast(lhsQuantity):
			return lhsQuantity >= rhsQuantity
		case let .exactly(lhsQuantity):
			return lhsQuantity >= rhsQuantity
		}
	}
}
