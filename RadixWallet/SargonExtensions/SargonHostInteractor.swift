import Sargon

final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock

	func signTransactions(request: SignRequestOfTransactionIntent) async throws -> SignResponseOfTransactionIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfTransactionIntentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signTransaction(input: perFactorSource)

			let outcome: FactorOutcomeOfTransactionIntentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.HostInteractionAborted

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.transaction(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func signSubintents(request: SignRequestOfSubintent) async throws -> SignResponseOfSubintentHash {
		var perFactorOutcome: [PerFactorOutcomeOfSubintentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signSubintent(input: perFactorSource)

			let outcome: FactorOutcomeOfSubintentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.HostInteractionAborted

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.subintent(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func signAuth(request: SignRequestOfAuthIntent) async throws -> SignResponseOfAuthIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfAuthIntentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signAuth(input: perFactorSource)

			let outcome: FactorOutcomeOfAuthIntentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.HostInteractionAborted

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.auth(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func deriveKeys(request: KeyDerivationRequest) async throws -> KeyDerivationResponse {
		var perFactorOutcome: [KeyDerivationResponsePerFactorSource] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.derivePublicKeys(input: perFactorSource, purpose: request.derivationPurpose)

			switch action {
			case .derivePublicKeys(.cancelled):
				throw CommonError.HostInteractionAborted

			case let .derivePublicKeys(.finished(factorInstances)):
				perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, factorInstances: factorInstances))

			default:
				fatalError("Unexpected action")
			}
		}

		return .init(perFactorSource: perFactorOutcome)
	}

	func requestAuthorization(purpose: AuthorizationPurpose) async -> AuthorizationResponse {
		let action = await overlayWindowClient.authorize(purpose: purpose)

		switch action {
		case .authorization(.cancelled):
			return .rejected

		case .authorization(.authorized):
			return .authorized

		default:
			fatalError("Unexpected action")
		}
	}
}
