// MARK: - DerivePublicKeys
@Reducer
struct DerivePublicKeys: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let input: KeyDerivationRequestPerFactorSource
		var factorSourceAccess: FactorSourceAccess.State?

		init(input: KeyDerivationRequestPerFactorSource, purpose: DerivationPurpose) {
			self.input = input
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: purpose.factorSourceAccessPurpose)
		}
	}

	typealias Action = FeatureAction<Self>

	enum InternalAction: Sendable, Hashable {
		case deriveWithSpecificPrivateHD__MustImplement
	}

	@CasePathable
	enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case cancelled
		case finished([HierarchicalDeterministicFactorInstance])
	}

	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.factorSourceAccess, action: \.child.factorSourceAccess) {
				FactorSourceAccess()
			}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			derivePublicKeys(factorSource: factorSource, input: state.input)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
		default:
			.none
		}
	}
}

private extension DerivePublicKeys {
	func derivePublicKeys(factorSource: FactorSource, input: KeyDerivationRequestPerFactorSource) -> Effect<Action> {
		.run { send in
			let factorInstances = switch factorSource {
			case .device:
				try await deviceFactorSourceClient.derivePublicKeys(input)

			case let .ledger(ledger):
				try await ledgerHardwareWalletClient.derivePublicKeys(.init(ledger: ledger, input: input))

			default:
				fatalError("Not implemented")
			}
			await send(.delegate(.finished(factorInstances)))
		} catch: { error, send in
			await handleError(factorSource: factorSource, error: error, send: send)
		}
	}

	private func handleError(factorSource: FactorSource, error: Error, send: Send<DerivePublicKeys.Action>) async {
		switch factorSource.kind {
		case .device:
			if !error.isUserCanceledKeychainAccess {
				// If user cancelled the operation, we will allow them to retry.
				// In any other situation we handle the error.
				errorQueue.schedule(error)
			}

		default:
			errorQueue.schedule(error)
		}
	}
}

private extension DerivationPurpose {
	var factorSourceAccessPurpose: FactorSourceAccess.State.Purpose {
		switch self {
		case .creatingNewAccount:
			.createAccount
		case .creatingNewPersona:
			.createPersona
		case .accountRecovery:
			.deriveAccounts
		case .securifyingAccount, .securifyingPersona, .securifyingAccountsAndPersonas, .preDerivingKeys:
			fatalError("Not yet supported")
		}
	}
}
