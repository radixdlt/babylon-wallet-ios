import Sargon

final class SargonHostInteractor: HostInteractor {
	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignWithFactorsOutcomeOfTransactionIntentHash {
		var responses: [SignaturesPerFactorSourceOfTransactionIntentHash] = []

		for request in request.perFactorSource {
			for transaction in request.transactions {
				let transactionIntent = transaction.payload.decompile()
				let ownedFactorInstances = transaction.ownedFactorInstances

				let result = try await SargonOS.shared.signTransaction(transactionIntent: transactionIntent, roleKind: .primary)
				for signature in result.intentSignatures.signatures {
					responses.append(
						.init(
							factorSourceId: transaction.factorSourceId,
							hdSignatures: [.init(
								input: .init(
									payloadId: transactionIntent.hash(),
									ownedFactorInstance: ownedFactorInstances.first! // what should go here?
								),
								signature: signature.signatureWithPublicKey
							)]
						)
					)
				}
			}
		}

		return .signed(producedSignatures: .init(perFactorSource: responses))
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
