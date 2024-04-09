// MARK: - FactorSourceAccess
public struct FactorSourceAccess: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let kind: Kind
		public let purpose: Purpose

		public init(kind: Kind, purpose: Purpose) {
			self.kind = kind
			self.purpose = purpose
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case retryButtonTapped
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case perform
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask, .retryButtonTapped:
			.send(.delegate(.perform))
		case .closeButtonTapped:
			.none
		}
	}
}

extension FactorSourceAccess.State {
	public enum Kind: Sendable, Hashable {
		case device
		case ledger(LedgerHardwareWalletFactorSource?)
	}

	public enum Purpose: Sendable, Hashable {
		/// Signing transactions.
		case signature

		/// Adding a new account.
		case createAccount

		/// Recovery of existing accounts.
		case deriveAccounts

		/// ROLA proof of accounts/personas.
		case proveOwnership

		/// Encrypting messages on transactions.
		case encryptMessage

		/// MFA signing, ROLA or encryption.
		case createKey
	}
}
