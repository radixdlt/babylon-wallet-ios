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

		init(input: PerFactorSourceInputOfAuthIntent) {
			self.purpose = .auth(input)
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: .proveOwnership)
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(NewFactorSourceAccess.Action)
	}

	enum InternalAction: Sendable, Hashable {
		case handleSignatures(FactorSource, Signatures)
	}

	enum DelegateAction: Sendable, Equatable {
		case skippedFactorSource
		case cancelled
		case finished(Signatures)
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

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .handleSignatures(factorSource, signatures):
			.send(.delegate(.finished(signatures)))
				.merge(with: updateLastUsed(factorSource: factorSource))
		}
	}
}

private extension NewSigning {
	func sign(purpose: State.Purpose, factorSource: FactorSource) -> Effect<Action> {
		.run { send in
			switch factorSource.kind {
			case .device:
				let signatures = try await signDevice(purpose: purpose)
				await send(.internal(.handleSignatures(factorSource, signatures)))

			case .ledgerHqHardwareWallet:
				guard let ledger = factorSource.asLedger else {
					throw WrongFactorSource()
				}
				do {
					let signatures = try await signLedger(purpose: purpose, ledger: ledger)
					await send(.internal(.handleSignatures(factorSource, signatures)))
				} catch {
					if error.isUserRejectedSigningOnLedgerDevice {
						// If user rejected signature on ledger device, we will inform the delegate to dismiss the signing sheet.
						await send(.delegate(.cancelled))
					} else {
						throw error
					}
				}

			default:
				fatalError("Not implemented")
			}
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	func signDevice(purpose: State.Purpose) async throws -> Signatures {
		switch purpose {
		case let .transaction(input):
			try await .transaction(deviceFactorSourceClient.signTransaction(input: input))

		case let .subintent(input):
			try await .subintent(deviceFactorSourceClient.signSubintent(input: input))

		case let .auth(input):
			try await .auth(deviceFactorSourceClient.signAuth(input: input))
		}
	}

	func signLedger(purpose: State.Purpose, ledger: LedgerHardwareWalletFactorSource) async throws -> Signatures {
		switch purpose {
		case let .transaction(input):
			let result = try await input.perTransaction.asyncMap { transaction in
				try await ledgerHardwareWalletClient.newSignTransaction(.init(ledger: ledger, input: transaction))
			}.flatMap { $0 }

			return .transaction(result)

		case let .subintent(input):
			let result = try await input.perTransaction.asyncCompactMap { transaction in
				try await ledgerHardwareWalletClient.signSubintent(.init(ledger: ledger, input: transaction))
			}.flatMap { $0 }

			return .subintent(result)

		case let .auth(input):
			let result = try await input.perTransaction.asyncCompactMap { transaction in
				try await ledgerHardwareWalletClient.signAuth(.init(ledger: ledger, input: transaction))
			}.flatMap { $0 }

			return .auth(result)
		}
	}

	func updateLastUsed(factorSource: FactorSource) -> Effect<Action> {
		.run { _ in
			try? await factorSourcesClient.updateLastUsed(.init(factorSourceId: factorSource.id))
		}
	}
}

// MARK: - NewSigning.State.Purpose
extension NewSigning.State {
	enum Purpose: Sendable, Hashable {
		case transaction(PerFactorSourceInputOfTransactionIntent)
		case subintent(PerFactorSourceInputOfSubintent)
		case auth(PerFactorSourceInputOfAuthIntent)
	}
}

// MARK: - NewSigning.Signatures
extension NewSigning {
	enum Signatures: Sendable, Hashable {
		case transaction([HdSignatureOfTransactionIntentHash])
		case subintent([HdSignatureOfSubintentHash])
		case auth([HdSignatureOfAuthIntentHash])
	}
}

private extension Error {
	var isUserRejectedSigningOnLedgerDevice: Bool {
		guard let error = self as? P2P.ConnectorExtension.Response.LedgerHardwareWallet.Failure else {
			return false
		}
		return error.code == .userRejectedSigningOfTransaction
	}
}

// MARK: - WrongFactorSource
struct WrongFactorSource: Swift.Error {}
