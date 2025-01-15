// MARK: - NewSigning
@Reducer
struct NewSigning: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let purpose: Purpose
		var factorSourceAccess: NewFactorSourceAccess.State

		init(input: PerFactorSourceInputOfTransactionIntent) {
			self.purpose = .transaction(input)
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: .signature)
		}

		init(input: PerFactorSourceInputOfSubintent) {
			self.purpose = .subintent(input)
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: .signature)
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(NewFactorSourceAccess.Action)
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
			NewFactorSourceAccess()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			sign(purpose: state.purpose, factorSource: factorSource)
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
	func sign(purpose: State.Purpose, factorSource: FactorSource) -> Effect<Action> {
		switch purpose {
		case let .transaction(input):
			signTransaction(input: input, factorSource: factorSource)
		case let .subintent(input):
			signSubintent(input: input, factorSource: factorSource)
		}
	}

	func signTransaction(input: PerFactorSourceInputOfTransactionIntent, factorSource: FactorSource) -> Effect<Action> {
		.run { send in
			let producedSignatures: [HdSignatureOfTransactionIntentHash]
			switch input.factorSourceId.kind {
			case .device:
				producedSignatures = try await deviceFactorSourceClient.signTransaction(input: input)

			case .ledgerHqHardwareWallet:
				guard let ledger = factorSource.asLedger else {
					struct WrongFactorSource: Swift.Error {}
					throw WrongFactorSource()
				}
				producedSignatures = try await signTransactionLedger(ledger: ledger, input: input)

			default:
				fatalError("Not implemented")
			}

			await send(.delegate(.finished(.transaction(producedSignatures))))

		} catch: { error, send in
			if let error = error as? P2P.ConnectorExtension.Response.LedgerHardwareWallet.Failure, error.code == .userRejectedSigningOfTransaction {
				// If user rejected transaction on ledger device, we will inform the delegate to dismiss the signing sheet.
				await send(.delegate(.cancelled))
			} else {
				errorQueue.schedule(error)
			}
		}
	}

	func signSubintent(input: PerFactorSourceInputOfSubintent, factorSource: FactorSource) -> Effect<Action> {
		.run { send in
			let producedSignatures: [HdSignatureOfSubintentHash]
			switch input.factorSourceId.kind {
			case .device:
				producedSignatures = try await deviceFactorSourceClient.signSubintent(input: input)

			case .ledgerHqHardwareWallet:
				guard let ledger = factorSource.asLedger else {
					struct WrongFactorSource: Swift.Error {}
					throw WrongFactorSource()
				}
				producedSignatures = try await signSubintentLedger(ledger: ledger, input: input)

			default:
				fatalError("Not implemented")
			}

			await send(.delegate(.finished(.subintent(producedSignatures))))
		} catch: { error, send in
			if let error = error as? P2P.ConnectorExtension.Response.LedgerHardwareWallet.Failure, error.code == .userRejectedSigningOfTransaction {
				// If user rejected transaction on ledger device, we will inform the delegate to dismiss the signing sheet.
				await send(.delegate(.cancelled))
			} else {
				errorQueue.schedule(error)
			}
		}
	}

	func signTransactionLedger(ledger: LedgerHardwareWalletFactorSource, input: PerFactorSourceInputOfTransactionIntent) async throws -> [HdSignatureOfTransactionIntentHash] {
		var result: [HdSignatureOfTransactionIntentHash] = []

		for transaction in input.perTransaction {
			let signatures = try await ledgerHardwareWalletClient.newSignTransaction(.init(ledger: ledger, input: transaction))
			result.append(contentsOf: signatures)
		}

		return result
	}

	func signSubintentLedger(ledger: LedgerHardwareWalletFactorSource, input: PerFactorSourceInputOfSubintent) async throws -> [HdSignatureOfSubintentHash] {
		var result: [HdSignatureOfSubintentHash] = []

		for transaction in input.perTransaction {
			let signatures = try await ledgerHardwareWalletClient.signSubintent(.init(ledger: ledger, input: transaction))
			result.append(contentsOf: signatures)
		}

		return result
	}
}

// MARK: - NewSigning.State.Purpose
extension NewSigning.State {
	enum Purpose: Sendable, Hashable {
		case transaction(PerFactorSourceInputOfTransactionIntent)
		case subintent(PerFactorSourceInputOfSubintent)
	}
}

// MARK: - NewSigning.Output
extension NewSigning {
	enum Output: Sendable, Hashable {
		case transaction([HdSignatureOfTransactionIntentHash])
		case subintent([HdSignatureOfSubintentHash])
	}
}
