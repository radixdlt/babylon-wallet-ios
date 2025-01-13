import Sargon

final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignResponseOfTransactionIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfTransactionIntentHash] = []

		for perFactorSource in request.perFactorSource {
//			let outcome = FactorOutcomeOfTransactionIntentHash.signed(
//				producedSignatures: [HdSignatureOfTransactionIntentHash(
//					input: .init(
//						payloadId: <#T##TransactionIntentHash#>, // perTransaction[0].payload.decompile().hash()
//						ownedFactorInstance: <#T##OwnedFactorInstance#> // have it in perTransaction[0].ownedFactorInstances
//					),
//					signature: <#T##SignatureWithPublicKey#> // have it in SigantureOfEntity
//				)]
//			)
		}

//		for perFactorSource in request.perFactorSource {
//			// let action = await overlayWindowClient.requestSignatutures(state: .init(input: perFactorSource))
//
//			for transaction in perFactorSource.perTransaction {
//				let action = await overlayWindowClient.requestSignatutures(state: .init(input: transaction))
//				let factorSourceId = transaction.factorSourceId
//				let outcome: FactorOutcomeOfTransactionIntentHash
//				switch action {
//				case .signing(.cancelSigning), .dismiss:
//					throw CommonError.SigningRejected
//				//case .signing(.skip):
//					//outcome = .neglected(.init(reason: .userExplicitlySkipped, factor: factorSourceId))
//
//				case .signing(.failedToSign):
//					outcome = .neglected(.init(reason: .failure, factor: factorSourceId)) // this won't actually be possible
//
//				case let .signing(.finishedSigning(.signTransaction(response, _))):
//					// TODO: We should get something like state.signatures from values to transform it here
//					transaction.
//					outcome = .signed(producedSignatures: [])
//
//				case .signing(.finishedSigning(.signAuth)), .signing(.finishedSigning(.signPreAuthorization)):
//					fatalError("Unexpected Signature when signing transactions")
//				}
//
//				perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))
//			}
//		}

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
