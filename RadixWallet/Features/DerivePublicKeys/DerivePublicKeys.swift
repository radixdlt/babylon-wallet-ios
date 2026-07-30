// MARK: - DerivePublicKeys
@Reducer
struct DerivePublicKeys: FeatureReducer {
	@Dependency(\.arculusCardClient) var arculusCardClient
	@ObservableState
	struct State: Hashable {
		let input: KeyDerivationRequestPerFactorSource
		var factorSourceAccess: FactorSourceAccess.State

		init(input: KeyDerivationRequestPerFactorSource, purpose: DerivationPurpose) {
			self.input = input
			self.factorSourceAccess = .init(id: input.factorSourceId, purpose: purpose.factorSourceAccessPurpose)
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ChildAction: Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	enum DelegateAction: Equatable {
		case cancelled
		case finished([HierarchicalDeterministicFactorInstance])
	}

	enum InternalAction: Hashable {
		case handleFactorInstances([HierarchicalDeterministicFactorInstance])
	}

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
		case let .factorSourceAccess(.delegate(.perform(factorSource))):
			derivePublicKeys(factorSource: factorSource, input: state.input)
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancelled))
		default:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .handleFactorInstances(factorInstances):
			.send(.delegate(.finished(factorInstances)))
		}
	}
}

private extension DerivePublicKeys {
	func derivePublicKeys(factorSource: PrivateFactorSource, input: KeyDerivationRequestPerFactorSource) -> Effect<Action> {
		.run { send in
			let factorInstances = switch factorSource {
			case let .device(_, mnemonicWithPassphrase):
				mnemonicWithPassphrase.derivePublicKeys(
					paths: input.derivationPaths,
					factorSourceId: input.factorSourceId
				)

			case let .ledger(ledger):
				try await ledgerHardwareWalletClient.derivePublicKeys(.init(ledger: ledger, input: input))

			case let .offDeviceMnemonic(_, mnemonicWithPassphrase):
				mnemonicWithPassphrase.derivePublicKeys(
					paths: input.derivationPaths,
					factorSourceId: input.factorSourceId
				)

			case let .arculusCard(arculus, _):
				try await arculusCardClient.derivePublicKeys(arculus, input.derivationPaths)

			default:
				fatalError("Not implemented")
			}
			await send(.internal(.handleFactorInstances(factorInstances)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

private extension DerivationPurpose {
	var factorSourceAccessPurpose: FactorSourceAccess.State.Purpose {
		switch self {
		case .accountRecovery:
			.deriveAccounts
		case .creatingNewAccount:
			.createAccountAuthorization
		case .creatingNewPersona:
			.createPersonaAuthorization
		case .securifyingAccount, .securifyingPersona, .securifyingAccountsAndPersonas, .preDerivingKeys:
			.updateFactorConfig
		}
	}
}
