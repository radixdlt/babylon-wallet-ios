// MARK: - RecoverWalletWithoutProfileStart
struct RecoverWalletWithoutProfileStart: FeatureReducer {
	struct State: Hashable {
		@PresentationState
		var destination: Destination.State? = nil

		init() {}
	}

	enum ViewAction: Equatable {
		case recoverWithBDFSTapped
		case ledgerOnlyTapped
		case olympiaOnlyTapped
		case closeTapped
	}

	enum DelegateAction: Equatable {
		case dismiss
		case backToStartOfOnboarding
		case recoverWithBDFSOnly
	}

	struct Destination: DestinationReducer {
		enum State: Hashable {
			case alert(AlertState<Action.AlertAction>)
		}

		enum Action: Hashable {
			case alert(AlertAction)

			enum AlertAction {
				case cancelTapped
				case continueTapped
			}
		}

		var body: some ReducerOf<Self> {
			EmptyReducer()
		}
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
