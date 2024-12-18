import Sargon

// MARK: - SargonHostInteractor
final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignWithFactorsOutcomeOfTransactionIntentHash {
		var responses: [SignaturesPerFactorSourceOfTransactionIntentHash] = []

		for request in request.perFactorSource {
			for transaction in request.transactions {
				let action = await overlayWindowClient.requestSignatutures(state: .init(input: transaction))
				switch action {
				case .signing(.cancelSigning), .signing(.failedToSign), .dismiss:
					return .neglected(.init(reason: .userExplicitlySkipped, factors: [transaction.factorSourceId]))
				case let .signing(.finishedSigning(.signTransaction(response, origin))):
					responses.append(
						.init(
							factorSourceId: transaction.factorSourceId,
							hdSignatures: [] // TODO: We should get something like state.signatures from values to transform it here
						)
					)
				case .signing(.finishedSigning(.signAuth)), .signing(.finishedSigning(.signPreAuthorization)):
					fatalError("Unepected Signature when signing transactions")
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

private extension OwnedFactorInstance {
	var factorSourceAccessKind: FactorSourceAccess.State.Kind {
		switch factorInstance.factorSourceId.kind {
		case .device:
			.device
		case .ledgerHqHardwareWallet:
			.ledger(nil) // TODO: How to populate Ledger Nano details?
		default:
			fatalError("Not supported")
		}
	}
}
