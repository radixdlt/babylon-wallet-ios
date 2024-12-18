import Sargon

final class SargonHostInteractor: HostInteractor {
	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignWithFactorsOutcomeOfTransactionIntentHash {
		throw CommonError.SigningRejected
	}

	func signSubintents(request: SargonUniFFI.SignRequestOfSubintent) async throws -> SargonUniFFI.SignWithFactorsOutcomeOfSubintentHash {
		throw CommonError.SigningRejected
	}

	func deriveKeys(request: SargonUniFFI.KeyDerivationRequest) async throws -> SargonUniFFI.KeyDerivationResponse {
		throw CommonError.SigningRejected
	}

	func signAuth(request: SargonUniFFI.AuthenticationSigningRequest) async throws -> SargonUniFFI.AuthenticationSigningResponse {
		throw CommonError.SigningRejected
	}
}
