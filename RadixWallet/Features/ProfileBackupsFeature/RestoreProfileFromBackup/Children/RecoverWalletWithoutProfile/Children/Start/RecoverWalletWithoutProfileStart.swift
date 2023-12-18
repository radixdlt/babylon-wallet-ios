// MARK: - RecoverWalletWithoutProfileStart
public struct RecoverWalletWithoutProfileStart: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State? = nil

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case recoverWithBDFSTapped
		case ledgerOnlyTapped
		case olympiaOnlyTapped
		case closeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case backToStartOfOnboarding
		case recoverWithBDFSOnly
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case alert(AlertState<Action.AlertAction>)
		}

		public enum Action: Sendable, Hashable {
			case alert(AlertAction)

			public enum AlertAction: Sendable {
				case cancelTapped
				case continueTapped
			}
		}

		public var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .recoverWithBDFSTapped:
			return .send(.delegate(.recoverWithBDFSOnly))

		case .ledgerOnlyTapped:
			state.destination = .alert(.alert(
				title: L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertTitle,
				message: L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertMessageHardware
			))
			return .none

		case .olympiaOnlyTapped:
			state.destination = .alert(.alert(
				title: L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertTitle,
				message: L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertMessageOlympia
			))
			return .none

		case .closeTapped:
			return .send(.delegate(.dismiss))
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .alert(.cancelTapped):
			state.destination = nil
			return .none

		case .alert(.continueTapped):
			state.destination = nil
			return .send(.delegate(.backToStartOfOnboarding))
		}
	}
}

private extension AlertState<RecoverWalletWithoutProfileStart.Destination.Action.AlertAction> {
	static func alert(title: String, message: String) -> Self {
		AlertState(
			title: .init(title),
			message: .init(message),
			buttons: [
				.default(.init(L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertContinue), action: .send(.continueTapped)),
				.cancel(.init(L10n.RecoverWalletWithoutProfile.Start.useNewWalletAlertCancel), action: .send(.cancelTapped)),
			]
		)
	}
}
