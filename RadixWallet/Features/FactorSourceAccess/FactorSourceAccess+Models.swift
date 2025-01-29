import Foundation

// MARK: - FactorSourceAccess.State.Purpose
extension FactorSourceAccess.State {
	enum Purpose: Sendable, Hashable {
		case signature

		/// Adding a new account.
		case createAccount

		/// Adding a new persona.
		case createPersona

		/// Recovery of existing accounts.
		case deriveAccounts

		/// ROLA proof of accounts/personas.
		case proveOwnership

		/// Encrypting messages on transactions.
		case encryptMessage

		/// MFA signing, ROLA or encryption.
		case createKey

		case authorization(AuthorizationPurpose)
	}
}
