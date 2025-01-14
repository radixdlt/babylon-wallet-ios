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

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum InternalAction: Sendable, Hashable {
		case fetchedFactorSource(FactorSource)
	}

	enum DelegateAction: Sendable, Equatable {
		case skippedFactorSource
		case cancelled
		case finished(Output)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .fetchedFactorSource(.ledger(ledger)):
			state.factorSourceAccess = .init(kind: .ledger(ledger), purpose: .signature)
			return .none
		default:
			return .none
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
			let producedSignatures: [HdSignatureOfTransactionIntentHash]
			switch input.factorSourceId.kind {
			case .device:
				producedSignatures = try await deviceFactorSourceClient.signUsingDeviceFactorSource(input: input)
			case .ledgerHqHardwareWallet:
				guard let ledger = try await factorSourcesClient.getFactorSource(
					id: input.factorSourceId.asGeneral,
					as: LedgerHardwareWalletFactorSource.self
				) else {
					struct LedgerFactorSourcenNotFound: Swift.Error {}
					throw LedgerFactorSourcenNotFound()
				}
				await send(.internal(.fetchedFactorSource(ledger.asGeneral)))
				producedSignatures = try await signTransactionLedger(ledger: ledger, input: input)
			default:
				fatalError("Not implemented")
			}

			await send(.delegate(.finished(.transaction(producedSignatures))))

		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func signTransactionLedger(ledger: LedgerHardwareWalletFactorSource, input: PerFactorSourceInputOfTransactionIntent) async throws -> [HdSignatureOfTransactionIntentHash] {
		var result: [HdSignatureOfTransactionIntentHash] = []

		for transaction in input.perTransaction {
			let signatures = try await ledgerHardwareWalletClient.newSignTransaction(.init(ledger: ledger, input: transaction))
			// let payloadId = transaction.payload.decompile().hash()
			result.append(contentsOf: signatures)
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
