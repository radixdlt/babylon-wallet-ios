import Sargon

final class SargonHostInteractor: HostInteractor {
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.continuousClock) var clock

	func signTransactions(request: SargonUniFFI.SignRequestOfTransactionIntent) async throws -> SargonUniFFI.SignResponseOfTransactionIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfTransactionIntentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signTransaction(input: perFactorSource)

			let outcome: FactorOutcomeOfTransactionIntentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.SigningRejected

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.transaction(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))

			// NOTE: Adding this delay among factor sources so that it gives time of dismissing previous factor source before presenting new one
			try? await clock.sleep(for: .seconds(0.9))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func signSubintents(request: SargonUniFFI.SignRequestOfSubintent) async throws -> SargonUniFFI.SignResponseOfSubintentHash {
		var perFactorOutcome: [PerFactorOutcomeOfSubintentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signSubintent(input: perFactorSource)

			let outcome: FactorOutcomeOfSubintentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.SigningRejected

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.subintent(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))

			// NOTE: Adding this delay among factor sources so that it gives time of dismissing previous factor source before presenting new one
			try? await clock.sleep(for: .seconds(0.9))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func signAuth(request: SargonUniFFI.SignRequestOfAuthIntent) async throws -> SargonUniFFI.SignResponseOfAuthIntentHash {
		var perFactorOutcome: [PerFactorOutcomeOfAuthIntentHash] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.signAuth(input: perFactorSource)

			let outcome: FactorOutcomeOfAuthIntentHash = switch action {
			case .signing(.cancelled):
				throw CommonError.SigningRejected

			case .signing(.skippedFactorSource):
				.neglected(.init(reason: .userExplicitlySkipped, factor: perFactorSource.factorSourceId))

			case let .signing(.finished(.auth(signatures))):
				.signed(producedSignatures: signatures)

			default:
				fatalError("Unexpected action")
			}
			perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, outcome: outcome))

			// NOTE: Adding this delay among factor sources so that it gives time of dismissing previous factor source before presenting new one
			try? await clock.sleep(for: .seconds(0.9))
		}

		return .init(perFactorOutcome: perFactorOutcome)
	}

	func deriveKeys(request: SargonUniFFI.KeyDerivationRequest) async throws -> SargonUniFFI.KeyDerivationResponse {
		var perFactorOutcome: [KeyDerivationResponsePerFactorSource] = []

		for perFactorSource in request.perFactorSource {
			let action = await overlayWindowClient.derivePublicKeys(input: perFactorSource, purpose: request.derivationPurpose)

			switch action {
			case .derivePublicKeys(.cancelled):
				throw CommonError.SigningRejected // TODO: What should be the error?

			case let .derivePublicKeys(.finished(factorInstances)):
				perFactorOutcome.append(.init(factorSourceId: perFactorSource.factorSourceId, factorInstances: factorInstances))

			default:
				fatalError("Unexpected action")
			}

			// NOTE: Adding this delay among factor sources so that it gives time of dismissing previous factor source before presenting new one
			try? await clock.sleep(for: .seconds(0.9))
		}

		return .init(perFactorSource: perFactorOutcome)
	}
}
