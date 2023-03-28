import FeaturePrelude

// MARK: - SelectAccountsToImport
public struct SelectAccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let availableAccounts: IdentifiedArrayOf<ImportedOlympiaWallet.Account>
		var selectedAccounts: [ImportedOlympiaWallet.Account]?
		public let selectionRequirement: SelectionRequirement = .atLeast(1)

		public init(
			scannedAccounts availableAccounts: NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>,
			selectedAccounts: [ImportedOlympiaWallet.Account]? = nil
		) {
			self.availableAccounts = IdentifiedArrayOf(uniqueElements: availableAccounts.rawValue.elements, id: \.id)
			self.selectedAccounts = selectedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedAccountsChanged([ImportedOlympiaWallet.Account]?)
		case continueButtonTapped([ImportedOlympiaWallet.Account])
	}

	public enum DelegateAction: Sendable, Equatable {
		case selectedAccounts(NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .selectedAccountsChanged(selectedAccounts):
			state.selectedAccounts = selectedAccounts
			return .none

		case let .continueButtonTapped(selectedAccountsArray):
			guard
				case let selectedAccountsSet = OrderedSet(selectedAccountsArray),
				let selectedAccounts = NonEmpty<OrderedSet<ImportedOlympiaWallet.Account>>(rawValue: selectedAccountsSet)
			else {
				if state.selectionRequirement >= 1 {
					assertionFailure("Should not be possible to jave se;ected")
				}
				return .none
			}
			return .send(.delegate(.selectedAccounts(selectedAccounts)))
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
