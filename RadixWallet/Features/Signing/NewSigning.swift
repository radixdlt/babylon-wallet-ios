// MARK: - NewSigning
@Reducer
struct NewSigning: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let input: PerFactorSourceInputOfTransactionIntent
		let purpose: Purpose
		var factorSourceAccess: FactorSourceAccess.State

		init(input: PerFactorSourceInputOfTransactionIntent) {
			self.input = input
			self.purpose = .transaction
			switch input.factorSourceId.kind {
			case .device:
				self.factorSourceAccess = .init(kind: .device, purpose: .signature)
			default:
				// TODO: Support other than device
				fatalError("Signing with others factor sources not supported yet")
			}
		}
	}

	typealias Action = FeatureAction<Self>

	enum DelegateAction: Sendable, Equatable {
		case skippedFactorSource
		case cancelled
		case producedSignatures([HdSignatureOfTransactionIntentHash])
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient

	var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			signTransaction(state: state)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
//		case .factorSourceAccess(.delegate(.skip)):
//			.send(.delegate(.skipped))
		default:
			.none
		}
	}
}

private extension NewSigning {
	func signTransaction(state: State) -> Effect<Action> {
		.run { [input = state.input] send in
			var producedSignatures: [HdSignatureOfTransactionIntentHash] = []

			for transaction in input.perTransaction {
				let payloadId = transaction.payload.decompile().hash()
				let hash = payloadId.hash
				let signatures = try await deviceFactorSourceClient.signUsingDeviceFactorSource(factorSourceId: input.factorSourceId, perTransaction: input.perTransaction, hashedDataToSign: hash)

				for signature in signatures {
					producedSignatures.append(.init(input: .init(payloadId: payloadId, ownedFactorInstance: signature.ownedFactorInstance), signature: signature.signatureWithPublicKey))
				}
			}

			await send(.delegate(.producedSignatures(producedSignatures)))
		}
	}
}

// MARK: - NewSigning.State.Purpose
extension NewSigning.State {
	enum Purpose: Sendable, Hashable {
		case transaction
	}
}
