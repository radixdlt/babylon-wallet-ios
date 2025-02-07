import Foundation

// MARK: - FactorSourceAccess.State.Purpose
extension FactorSourceAccess.State {
	enum Purpose: Sendable, Hashable {
		/// Signing a transaction or a subintent.
		case signature

		/// Checking that user has access to the given Factor Source.
		case spotCheck(allowSkip: Bool)

		/// ROLA proof of accounts/personas.
		case proveOwnership

		/// Encrypting messages on transactions.
		case encryptMessage

		/// Filling key cache.
		case updateFactorConfig

		/// Scanning of existing accounts for recovery.
		case deriveAccounts

		/// Authorization before creating an Account.
		case createAccountAuthorization

		/// Authorization before creating a Persona.
		case createPersonaAuthorization
	}
}
