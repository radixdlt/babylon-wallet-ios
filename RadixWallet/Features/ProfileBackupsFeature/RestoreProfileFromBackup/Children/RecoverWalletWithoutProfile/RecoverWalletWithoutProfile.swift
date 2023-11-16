// MARK: - RecoverWalletWithoutProfile
public struct RecoverWalletWithoutProfile: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case recoverWithBDFSTapped
		case ledgerOnlyOrOlympiaOnlyTapped
		case closeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .recoverWithBDFSTapped:
			loggerGlobal.notice("recoverWithBDFSTapped")
			return .none

		case .ledgerOnlyOrOlympiaOnlyTapped:
			loggerGlobal.notice("ledgerOnlyOrOlympiaOnlyTapped")
			return .none

		case .closeTapped:
			return .send(.delegate(.dismiss))
		}
	}
}
