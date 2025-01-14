// MARK: - NewSigning
@Reducer
struct NewSigning: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let purpose: Purpose
		var factorSourceAccess: FactorSourceAccess.State

		init(input: PerFactorSourceInputOfTransactionIntent) {
			self.purpose = .transaction(input)
			switch input.factorSourceId.kind {
			case .device:
				self.factorSourceAccess = .init(kind: .device, purpose: .signature)
			case .ledgerHqHardwareWallet:
				// TODO: How do we get factor source here?
				self.factorSourceAccess = .init(kind: .ledger(nil), purpose: .signature)
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
		case finished(Output)
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: \.child.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			sign(state: state)
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
	func sign(state: State) -> Effect<Action> {
		switch state.purpose {
		case let .transaction(input):
			switch input.factorSourceId.kind {
			case .device:
				signTransactionDevice(input: input)
			case .ledgerHqHardwareWallet:
				fatalError("Not implemented")
			default:
				fatalError("Not implemented")
			}
		}
	}

	func signTransactionDevice(input: PerFactorSourceInputOfTransactionIntent) -> Effect<Action> {
		.run { [input = input] send in
			var producedSignatures: [HdSignatureOfTransactionIntentHash] = []

			for transaction in input.perTransaction {
				let payloadId = transaction.payload.decompile().hash()
				let hash = payloadId.hash
				let signatures = try await deviceFactorSourceClient.signUsingDeviceFactorSource(factorSourceId: input.factorSourceId, ownedFactorInstances: transaction.ownedFactorInstances, hashedDataToSign: hash)

				for signature in signatures {
					producedSignatures.append(.init(input: .init(payloadId: payloadId, ownedFactorInstance: signature.ownedFactorInstance), signature: signature.signatureWithPublicKey))
				}
			}

			await send(.delegate(.finished(.transaction(producedSignatures))))
		}
	}

	func signTransactionLedger(input: PerFactorSourceInputOfTransactionIntent) -> Effect<Action> {
		.run { [input = input] send in
			var producedSignatures: [HdSignatureOfTransactionIntentHash] = []

			for transaction in input.perTransaction {
				let payloadId = transaction.payload.decompile().hash()
				let hash = payloadId.hash
				// TODO:
			}

			await send(.delegate(.finished(.transaction(producedSignatures))))
		}
	}
}

// MARK: - NewSigning.State.Purpose
extension NewSigning.State {
	enum Purpose: Sendable, Hashable {
		case transaction(PerFactorSourceInputOfTransactionIntent)
	}
}

// MARK: - NewSigning.Output
extension NewSigning {
	enum Output: Sendable, Hashable {
		case transaction([HdSignatureOfTransactionIntentHash])
	}
}
