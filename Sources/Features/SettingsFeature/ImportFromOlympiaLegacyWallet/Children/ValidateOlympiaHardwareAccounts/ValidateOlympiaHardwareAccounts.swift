import AccountsClient // FIXME: move `OlympiaAccountToMigrate` to shared models?
import FeaturePrelude

// MARK: - ValidateOlympiaHardwareAccounts
public struct ValidateOlympiaHardwareAccounts: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		public let ledgerNanoFactorSourceID: FactorSourceID
		public init(
			hardwareAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>,
			ledgerNanoFactorSourceID: FactorSourceID
		) {
			self.hardwareAccounts = hardwareAccounts
			self.ledgerNanoFactorSourceID = ledgerNanoFactorSourceID
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case finishedButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedVerifyingAccounts(NonEmpty<OrderedSet<OlympiaAccountToMigrate>>, FactorSourceID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .finishedButtonTapped:
			return .send(.delegate(.finishedVerifyingAccounts(state.hardwareAccounts, state.ledgerNanoFactorSourceID)))
		}
	}
}
