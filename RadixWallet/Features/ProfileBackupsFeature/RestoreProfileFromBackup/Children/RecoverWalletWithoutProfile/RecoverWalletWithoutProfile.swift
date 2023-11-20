// MARK: - RecoverWalletWithoutProfile
public struct RecoverWalletWithoutProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case recoverWithBDFSTapped
		case ledgerOnlyOrOlympiaOnlyTapped
		case closeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case backToStartOfOnboarding
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case ledgerOrOlympiaOnlyAlert(AlertState<Action.LedgerOrOlympiaOnlyAction>)
			case recoverWithBDFSOnly(RecoverWalletControlWithBDFSOnly.State)
		}

		public enum Action: Sendable, Hashable {
			case ledgerOrOlympiaOnlyAlert(LedgerOrOlympiaOnlyAction)
			case recoverWithBDFSOnly(RecoverWalletControlWithBDFSOnly.Action)

			public enum LedgerOrOlympiaOnlyAction {
				case cancelTapped
				case continueTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.recoverWithBDFSOnly, action: /Action.recoverWithBDFSOnly) {
				RecoverWalletControlWithBDFSOnly()
			}
		}
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .recoverWithBDFSTapped:
			state.destination = .recoverWithBDFSOnly(.init())
			return .none

		case .ledgerOnlyOrOlympiaOnlyTapped:
			state.destination = .ledgerOrOlympiaOnlyAlert(.init(
				title: .init("No Babylon Seed Phrase"), // FIXME: Strings
				message: .init("Tap “I'm a New Wallet User”. After completing wallet creation, you can recover any Olympia or Ledger-based Accounts in Settings."), // FIXME: Strings
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.continueTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				]
			))
			return .none

		case .closeTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .ledgerOrOlympiaOnlyAlert(.cancelTapped):
			state.destination = nil
			return .none
		case .ledgerOrOlympiaOnlyAlert(.continueTapped):
			state.destination = nil
			return .send(.delegate(.backToStartOfOnboarding))

		default:
			return .none
		}
	}
}
