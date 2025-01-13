import Sargon

final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignResponseOfTransactionIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfTransactionIntentHash] = []

		for request in request.perFactorSource {
			for transaction in request.perTransaction {
				let action = await overlayWindowClient.requestSignatutures(state: .init(input: transaction))
				let factorSourceId = transaction.factorSourceId
				let outcome: FactorOutcomeOfTransactionIntentHash
				switch action {
				case .signing(.cancelSigning), .dismiss:
					outcome = .neglected(.init(reason: .userExplicitlySkipped, factor: factorSourceId))

				case .signing(.failedToSign):
					outcome = .neglected(.init(reason: .failure, factor: factorSourceId))

				case let .signing(.finishedSigning(.signTransaction(response, origin))):
					// TODO: We should get something like state.signatures from values to transform it here
					outcome = .signed(producedSignatures: [])

				case .signing(.finishedSigning(.signAuth)), .signing(.finishedSigning(.signPreAuthorization)):
					fatalError("Unexpected Signature when signing transactions")
				}

				perFactorOutcome.append(.init(factorSourceId: request.factorSourceId, outcome: outcome))
			}
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func signSubintents(request: SargonUniFFI.SignRequestOfSubintent) async throws -> SargonUniFFI.SignResponseOfSubintentHash {
		throw CommonError.SigningRejected
	}

	func deriveKeys(request: SargonUniFFI.KeyDerivationRequest) async throws -> SargonUniFFI.KeyDerivationResponse {
		throw CommonError.SigningRejected
	}

	func signAuth(request: SargonUniFFI.SignRequestOfAuthIntent) async throws -> SargonUniFFI.SignResponseOfAuthIntentHash {
		throw CommonError.SigningRejected
	}
}
