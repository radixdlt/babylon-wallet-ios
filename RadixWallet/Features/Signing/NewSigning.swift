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
	@Dependency(\.errorQueue) var errorQueue

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
			signTransaction(input: input)
		}
	}

	func signTransaction(input: PerFactorSourceInputOfTransactionIntent) -> Effect<Action> {
		.run { send in
			let producedSignatures: [HdSignatureOfTransactionIntentHash] = switch input.factorSourceId.kind {
			case .device:
				try await deviceFactorSourceClient.signUsingDeviceFactorSource(input: input)
			case .ledgerHqHardwareWallet:
				try await signTransactionLedger(input: input)
			default:
				fatalError("Not implemented")
			}

			await send(.delegate(.finished(.transaction(producedSignatures))))

		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func signTransactionLedger(input: PerFactorSourceInputOfTransactionIntent) async throws -> [HdSignatureOfTransactionIntentHash] {
		var result: [HdSignatureOfTransactionIntentHash] = []

		for transaction in input.perTransaction {
			let payloadId = transaction.payload.decompile().hash()
			let hash = payloadId.hash
			// TODO:
		}

		return result
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
