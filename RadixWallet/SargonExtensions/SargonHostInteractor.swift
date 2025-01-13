import Sargon

final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignResponseOfTransactionIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfTransactionIntentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signTransaction(input: perFactorSource)
			let outcome: FactorOutcomeOfTransactionIntentHash = switch action {
			case .newSigning(.cancelled):
				throw CommonError.SigningRejected
			case .newSigning(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))
			case let .newSigning(.producedSignatures(signatures)):
				.signed(producedSignatures: signatures)
			case .dismiss, .signing:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))
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
